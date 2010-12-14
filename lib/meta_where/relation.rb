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
        association_name ||= (default_association = reflect_on_all_associations.detect {|a| a.class_name == r.klass.name}) ?
                             default_association.name : r.table_name.to_sym
        r = r.clone
        r.where_values.map! {|w| MetaWhere::Visitors::Predicate.visitables.include?(w.class) ? {association_name => w} : w}
        r.joins_values.map! {|j| [Symbol, Hash, MetaWhere::JoinType].include?(j.class) ? {association_name => j} : j}
        self.joins_values += [association_name] if reflect_on_association(association_name)
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
        @create_with_value || predicates_without_conflicting_equality.inject({}) do |hash, where|
          if is_equality_predicate?(where)
            hash[where.left.name] = where.right.respond_to?(:value) ? where.right.value : where.right
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
          arel = arel.join(join.relation, Arel::Nodes::OuterJoin).on(*join.on)
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

    def predicates_without_conflicting_equality
      remove_conflicting_equality_predicates(flatten_predicates(@where_values, predicate_visitor))
    end

    # Very occasionally, we need to get a visitor for another relation, so it makes sense to factor
    # these out into a public method despite only being two lines long.
    def predicate_visitor
      join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(@klass, association_joins, custom_joins)
      MetaWhere::Visitors::Predicate.new(join_dependency)
    end

    def attribute_visitor
      join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(@klass, association_joins, custom_joins)
      MetaWhere::Visitors::Attribute.new(join_dependency)
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
      visitor = relation.attribute_visitor

      relation.order_values.map! {|o| visitor.can_accept?(o) ? visitor.accept(o).to_sql : o}

      super
    end

    def build_arel
      arel = table

      visitor = predicate_visitor

      arel = build_intelligent_joins(arel, visitor) if @joins_values.present?

      predicate_wheres = flatten_predicates(@where_values.uniq, visitor)

      arel = collapse_wheres(arel, (predicate_wheres - ['']).uniq)

      arel = arel.having(*flatten_predicates(@having_values, visitor).reject {|h| h.blank?}) unless @having_values.empty?

      arel = arel.take(@limit_value) if @limit_value
      arel = arel.skip(@offset_value) if @offset_value

      arel = arel.group(*@group_values.uniq.reject{|g| g.blank?}) unless @group_values.empty?

      arel = build_order(arel, attribute_visitor, @order_values) unless @order_values.empty?

      arel = build_select(arel, @select_values.uniq)

      arel = arel.from(@from_value) if @from_value
      arel = arel.lock(@lock_value) if @lock_value

      arel
    end

    def select(value = Proc.new)
      if MetaWhere::Function === value
        value.table = self.arel_table
      end

      super
    end

    private

    def is_equality_predicate?(predicate)
      predicate.class == Arel::Nodes::Equality
    end

    def build_intelligent_joins(arel, visitor)
      joined_associations = []

      visitor.join_dependency.graft(*stashed_association_joins)

      @implicit_readonly = true unless association_joins.empty? && stashed_association_joins.empty?

      to_join = []

      visitor.join_dependency.join_associations.each do |association|
        if (association_relation = association.relation).is_a?(Array)
          to_join << [association_relation.first, association.join_type, association.association_join.first]
          to_join << [association_relation.last, association.join_type, association.association_join.last]
        else
          to_join << [association_relation, association.join_type, association.association_join]
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

    def build_order(arel, visitor, orders)
      order_attributes = orders.map {|o|
        visitor.can_accept?(o) ? visitor.accept(o, visitor.join_dependency.join_base) : o
      }.flatten.uniq.reject {|o| o.blank?}
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

    def collapse_wheres(arel, wheres)
      binaries = wheres.grep(Arel::Nodes::Binary)

      groups = binaries.group_by do |binary|
        [binary.class, binary.left]
      end

      groups.each do |_, bins|
        test = bins.inject(bins.shift) do |memo, expr|
          memo.or(expr)
        end
        arel = arel.where(test)
      end

      (wheres - binaries).each do |where|
        where = Arel.sql(where) if String === where
        arel = arel.where(Arel::Nodes::Grouping.new(where))
      end
      arel
    end

    def flatten_predicates(predicates, visitor)
      predicates.map {|p|
        predicate = visitor.can_accept?(p) ? visitor.accept(p) : p
        if predicate.is_a?(Arel::Nodes::Grouping) && predicate.expr.is_a?(Arel::Nodes::And)
          flatten_predicates([predicate.expr.left, predicate.expr.right], visitor)
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
        [Hash, Array, Symbol, MetaWhere::JoinType].include?(j.class) && !array_of_strings?(j)
      }
    end

    def stashed_association_joins
      @mw_stashed_association_joins ||= unique_joins.grep(ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation)
    end

    def non_association_joins
      @mw_non_association_joins ||= (unique_joins - association_joins - stashed_association_joins).reject {|j| j.blank?}
    end

    def custom_joins
      @mw_custom_joins ||= custom_join_sql(*non_association_joins)
    end
  end
end