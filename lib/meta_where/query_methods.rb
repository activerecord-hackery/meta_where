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

      opts = args.first
      if [String, Array].include?(opts.class)
        @klass.send(:sanitize_sql, args.size > 1 ? args : opts)
      else
        predicates = []
        args.each do |arg|
          predicates += Array.wrap(
            case arg
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
    
    def build_arel_with_metawhere
      arel = table

      @joins_values.map! {|j| j.respond_to?(:strip) ? j.strip : j}.uniq!
      
      join_operations = @joins_values.select {|j| j.is_a?(ActiveRecord::Relation::JoinOperation)}
      
      # Do these first, since eager loading expects these column names
      join_operations.each do |join|
        arel = arel.join(join.relation, join.join_class).on(*join.on)
      end
      
      association_joins = @joins_values.select {|j| [Hash, Array, Symbol].include?(j.class) && !array_of_strings?(j)}
      
      to_join = []
      join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(@klass, association_joins, arel.joins(arel))
      
      # Build wheres now to take advantage of autojoin if needed
      builder = MetaWhere::PredicateBuilder.new(join_dependency, @autojoin_value)
      predicate_wheres = @where_values.map { |w|
        w.respond_to?(:to_predicate) ? w.to_predicate(builder, join_dependency.join_base) : w
      }.flatten.uniq
      
      join_dependency.join_associations.each do |association|
        if (association_relation = association.relation).is_a?(Array)
          to_join << [association_relation.first, association.association_join.first]
          to_join << [association_relation.last, association.association_join.last]
        else
          to_join << [association_relation, association.association_join]
        end
      end
      
      to_join.each do |tj|
        arel = arel.join(tj[0]).on(*tj[1])
      end

      (@joins_values - association_joins).each do |join|
        next if join.blank?

        @implicit_readonly = true

        case join
        when ActiveRecord::Relation::JoinOperation, Hash, Array, Symbol
          if array_of_strings?(join)
            join_string = join.join(' ')
            arel = arel.join(join_string)
          end
        else
          arel = arel.join(join)
        end
      end
      
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