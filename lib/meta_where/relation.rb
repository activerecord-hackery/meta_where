module MetaWhere
  module Relation

    def self.included(base)
      base.class_eval do
        alias_method_chain :reset, :metawhere
        alias_method_chain :scope_for_create, :metawhere
      end

      # We have to do this on the singleton to work with Ruby 1.8.7. Not sure why.
      base.instance_eval do
        alias_method :&, :merge
      end
    end

    def merge(r, association_name = nil)
      if (r && (association_name || base_class.name != r.klass.base_class.name)) # Merging relations with different base.
        association_name ||= (default_association = reflect_on_all_associations.detect {|a| a.klass.name == r.klass.name}) ?
                             default_association.name : r.table_name.to_sym
        r = r.clone
        r.where_values.map! {|w| w.respond_to?(:to_predicate) ? {association_name => w} : w}
        r.joins_values.map! {|j| [Symbol, Hash].include?(j.class) ? {association_name => j} : j}
        self.joins_values += [association_name]
      end

      super(r)
    end

    def reset_with_metawhere
      @mw_unique_joins = @mw_association_joins = @mw_non_association_joins =
        @mw_stashed_association_joins = @mw_custom_joins = nil
      reset_without_metawhere
    end

    def scope_for_create_with_metawhere
      @scope_for_create ||= begin
        @create_with_value || predicate_wheres.inject({}) do |hash, where|
          if is_equality_predicate?(where)
            hash[where.operand1.name] = where.operand2.respond_to?(:value) ? where.operand2.value : where.operand2
          end

          hash
        end
      end
    end

    def build_where(opts, other = [])
      if opts.is_a?(String)
        [@klass.send(:sanitize_sql, other.empty? ? opts : ([opts] + other))]
      else
        predicates = []
        [opts, *other].each do |arg|
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
      remove_conflicting_equality_predicates(flatten_predicates(@where_values, metawhere_builder))
    end

    # Very occasionally, we need to get a builder for another relation, so it makes sense to factor
    # this out into a public method despite only being two lines long.
    def metawhere_builder
      join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(@klass, association_joins, custom_joins)
      MetaWhere::Builder.new(join_dependency)
    end

    # Simulate the logic that occurs in ActiveRecord::Relation.to_a
    #
    # @records = eager_loading? ? find_with_associations : @klass.find_by_sql(arel.to_sql)
    #
    # This will let us get a dump of the SQL that will be run against the DB for debug
    # purposes without actually running the query.
    def debug_sql
      if eager_loading?
        including = (@eager_load_values + @includes_values).uniq
        join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(@klass, including, nil)
        construct_relation_for_association_find(join_dependency).to_sql
      else
        arel.to_sql
      end
    end

    def construct_limited_ids_condition(relation)
      builder = relation.metawhere_builder

      relation.order_values.map! {|o| o.respond_to?(:to_attribute) ? o.to_attribute(builder).to_sql : o}

      super
    end

    def build_arel
      arel = table

      builder = metawhere_builder

      arel = build_intelligent_joins(arel, builder) if @joins_values.present?

      predicate_wheres = remove_conflicting_equality_predicates(flatten_predicates(@where_values, builder))

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

      arel = arel.having(*@having_values.uniq.select{|h| h.present?}) if @having_values.present?

      arel = arel.take(@limit_value) if @limit_value.present?
      arel = arel.skip(@offset_value) if @offset_value.present?

      arel = arel.group(*@group_values.uniq.select{|g| g.present?}) if @group_values.present?

      arel = build_order(arel, builder, @order_values) if @order_values.present?

      arel = build_select(arel, @select_values.uniq)

      arel = arel.from(@from_value) if @from_value.present?

      case @lock_value
      when TrueClass
        arel = arel.lock
      when String
        arel = arel.lock(@lock_value)
      end if @lock_value.present?

      arel
    end

    private

    def is_equality_predicate?(predicate)
      predicate.respond_to?(:operator) && predicate.operator == :==
    end

    def build_intelligent_joins(arel, builder)
      joined_associations = []

      builder.join_dependency.graft(*stashed_association_joins)

      @implicit_readonly = true unless association_joins.empty? && stashed_association_joins.empty?

      to_join = []

      builder.join_dependency.join_associations.each do |association|
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
    end

    def build_order(arel, builder, orders)
      order_attributes = orders.map {|o|
        o.respond_to?(:to_attribute) ? o.to_attribute(builder, builder.join_dependency.join_base) : o
      }.flatten.uniq.select {|o| o.present?}
      order_attributes.map! {|a| Arel::SqlLiteral.new(a.is_a?(String) ? a : a.to_sql)}
      order_attributes.present? ? arel.order(*order_attributes) : arel
    end

    def remove_conflicting_equality_predicates(predicates)
      predicates.reverse.inject([]) { |ary, w|
        unless is_equality_predicate?(w) && ary.any? {|p| is_equality_predicate?(p) && p.operand1.name == w.operand1.name}
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