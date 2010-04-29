module MetaWhere
  module QueryMethods
    extend ActiveSupport::Concern
    
    included do
      alias_method_chain :build_arel, :metawhere
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
    
    def build_where(*args)
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
    end
        
    def build_arel_with_metawhere
      arel = table
      
      joined_associations = []
      association_joins = []

      joins = @joins_values.map {|j| j.respond_to?(:strip) ? j.strip : j}.uniq
      
      joins.each do |join|
        association_joins << join if [Hash, Array, Symbol].include?(join.class) && !array_of_strings?(join)
      end
      
      stashed_association_joins = joins.select {|j| j.is_a?(ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation)}
      non_association_joins = (joins - association_joins - stashed_association_joins).reject {|j| j.blank?}
      custom_joins = custom_join_sql(*non_association_joins)
            
      join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(@klass, association_joins, custom_joins)
      
      # Build wheres now to take advantage of autojoin if needed
      builder = MetaWhere::PredicateBuilder.new(join_dependency, @autojoin_value)
      predicate_wheres = @where_values.map { |w|
        w.respond_to?(:to_predicate) ? w.to_predicate(builder, join_dependency.join_base) : w
      }.flatten.uniq
      
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

      @group_values.uniq.each do |g|
        arel = arel.group(g) if g.present?
      end

      @order_values.uniq.each do |o|
        arel = arel.order(Arel::SqlLiteral.new(o.to_s)) if o.present?
      end

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
  end
end