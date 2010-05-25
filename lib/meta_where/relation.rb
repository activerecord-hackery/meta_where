module MetaWhere
  module Relation
    extend ActiveSupport::Concern
    
    included do
      alias_method_chain :build_arel, :metawhere
      alias_method_chain :build_where, :metawhere
      alias_method_chain :reset, :metawhere
      alias_method_chain :scope_for_create, :metawhere
      alias_method_chain :merge, :metawhere
      
      alias_method :&, :merge_with_metawhere
      
      const_get("SINGLE_VALUE_METHODS").push(:autojoin) # I'm evil.
      attr_accessor :autojoin_value

      class_eval <<-CEVAL, __FILE__
        def autojoin(value = true, &block)
          new_relation = clone
          new_relation.send(:apply_modules, Module.new(&block)) if block_given?
          new_relation.autojoin_value = value
          new_relation
        end
      CEVAL
    end
    
    def merge_with_metawhere(r, association_name = nil)
      if (r && klass != r.klass) # Merging relations with different base.
        default_association = reflect_on_all_associations.detect {|a| a.klass == r.klass}
        association_name ||= default_association ? default_association.name : r.table_name.to_sym
        r = r.clone
        r.where_values.map! {|w| w.respond_to?(:to_predicate) ? {association_name => w} : w}
        r.joins_values.map! {|j| [Symbol, Hash].include?(j.class) ? {association_name => j} : j}
      end
      
      merge_without_metawhere(r)
    end
    
    def reset_with_metawhere
      @mw_unique_joins = @mw_association_joins = @mw_non_association_joins = 
        @mw_stashed_association_joins = @mw_custom_joins = nil
      reset_without_metawhere
    end
    
    def scope_for_create_with_metawhere
      @scope_for_create ||= begin
        @create_with_value || predicate_wheres.inject({}) do |hash, where|
          if where.is_a?(Arel::Predicates::Equality)
            hash[where.operand1.name] = where.operand2.respond_to?(:value) ? where.operand2.value : where.operand2
          end

          hash
        end
      end
    end
    
    def build_where_with_metawhere(*args)
      return if args.blank?
      
      if args.first.is_a?(String)
        @klass.send(:sanitize_sql, args)
      else
        predicates = []
        args.each do |arg|
          predicates += Array.wrap(
            case arg
            when Array
              @klass.send(:sanitize_sql, arg)
            when Hash
              @klass.send(:expand_hash_conditions_for_aggregates, arg)
            else
              arg
            end
          )
        end
        predicates
      end
    end
    
    def build_custom_joins(joins = [], arel = nil)
      arel ||= table
      joins.each do |join|
        next if join.blank?
        
        @implicit_readonly = true
        
        case join
        when ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation
          arel = arel.join(join.relation, Arel::OuterJoin).on(*join.on)
        when Hash, Array, Symbol
          if array_of_strings?(join)
            join_string = join.join(' ')
            arel = arel.join(join_string)
          end
        else
          arel = arel.join(join)
        end
      end
      
      arel
    end
    
    def custom_join_sql(*joins)
      arel = table
      joins.each do |join|
        next if join.blank?
        
        @implicit_readonly = true
        
        case join
        when Hash, Array, Symbol
          if array_of_strings?(join)
            join_string = join.join(' ')
            arel = arel.join(join_string)
          end
        else
          arel = arel.join(join)
        end
      end
      arel.joins(arel)
    end unless defined?(:custom_join_sql)
    
    def predicate_wheres
      join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(@klass, association_joins, custom_joins)
      builder = MetaWhere::Builder.new(join_dependency, @autojoin_value)
      remove_conflicting_equality_predicates(flatten_predicates(@where_values, builder))
    end
    
    def build_arel_with_metawhere
      arel = table
      
      joined_associations = []
            
      join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(@klass, association_joins, custom_joins)
      
      # Build wheres now to take advantage of autojoin if needed
      builder = MetaWhere::Builder.new(join_dependency, @autojoin_value)
      predicate_wheres = remove_conflicting_equality_predicates(flatten_predicates(@where_values, builder))
      
      order_attributes = @order_values.map {|o|
        o.respond_to?(:to_attribute) ? o.to_attribute(builder, join_dependency.join_base) : o
      }.flatten.uniq.select {|o| o.present?}
      order_attributes.map! {|a| Arel::SqlLiteral.new(a.is_a?(String) ? a : a.to_sql)}
      
      join_dependency.graft(*stashed_association_joins)
      
      @implicit_readonly = true unless association_joins.empty? && stashed_association_joins.empty?
      
      to_join = []
      
      join_dependency.join_associations.each do |association|
        if (association_relation = association.relation).is_a?(Array)
          to_join << [association_relation.first, association.join_class, association.association_join.first]
          to_join << [association_relation.last, association.join_class, association.association_join.last]
        else
          to_join << [association_relation, association.join_class, association.association_join]
        end
      end
      
      to_join.each do |tj|
        unless joined_associations.detect {|ja| ja[0] == tj[0] && ja[1] == tj[1] && ja[2] == tj[2] }
          joined_associations << tj
          arel = arel.join(tj[0], tj[1]).on(*tj[2])
        end
      end
      
      arel = arel.join(custom_joins)
      
      predicate_wheres.each do |where|
        next if where.blank?
        
        case where
        when Arel::SqlLiteral
          arel = arel.where(where)
        else
          sql = where.is_a?(String) ? where : where.to_sql
          arel = arel.where(Arel::SqlLiteral.new("(#{sql})"))
        end
      end

      @having_values.uniq.each do |h|
        arel = h.is_a?(String) ? arel.having(h) : arel.having(*h)
      end

      arel = arel.take(@limit_value) if @limit_value.present?
      arel = arel.skip(@offset_value) if @offset_value.present?

      arel = arel.group(*@group_values.uniq.select{|g| g.present?})
      
      arel = arel.order(*order_attributes) if order_attributes.present?
      
      selects = @select_values.uniq

      quoted_table_name = @klass.quoted_table_name

      if selects.present?
        selects.each do |s|
          @implicit_readonly = false
          arel = arel.project(s) if s.present?
        end
      else
        arel = arel.project(quoted_table_name + '.*')
      end

      arel = @from_value.present? ? arel.from(@from_value) : arel.from(quoted_table_name)

      case @lock_value
      when TrueClass
        arel = arel.lock
      when String
        arel = arel.lock(@lock_value)
      end if @lock_value.present?

      arel
    end
    
    private
    
    def remove_conflicting_equality_predicates(predicates)
      predicates.reverse.inject([]) { |ary, w|
        unless w.is_a?(Arel::Predicates::Equality) && ary.any? {|p| p.is_a?(Arel::Predicates::Equality) && p.operand1.name == w.operand1.name}
          ary << w
        end
        ary
      }.reverse
    end
    
    def flatten_predicates(predicates, builder)
      predicates.map {|p|
        predicate = p.respond_to?(:to_predicate) ? p.to_predicate(builder) : p
        if predicate.is_a?(Arel::Predicates::All)
          flatten_predicates(predicate.predicates, builder)
        else
          predicate
        end
      }.flatten.uniq
    end
    
    def unique_joins
      @mw_unique_joins ||= @joins_values.map {|j| j.respond_to?(:strip) ? j.strip : j}.uniq
    end
    
    def association_joins
      @mw_association_joins ||= unique_joins.select{|j|
        [Hash, Array, Symbol].include?(j.class) && !array_of_strings?(j)
      }
    end
    
    def stashed_association_joins
      @mw_stashed_association_joins ||= unique_joins.select {|j| j.is_a?(ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation)}
    end
    
    def non_association_joins
      @mw_non_association_joins ||= (unique_joins - association_joins - stashed_association_joins).reject {|j| j.blank?}
    end
    
    def custom_joins
      @mw_custom_joins ||= custom_join_sql(*non_association_joins)
    end
  end
end