module MetaWhere
  module Adapters
    module ActiveRecord
      module Relation

        JoinAssociation = ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation
        JoinDependency = ::ActiveRecord::Associations::ClassMethods::JoinDependency

        attr_writer :join_dependency
        private :join_dependency=

        def join_dependency
          @join_dependency ||= (build_join_dependency(table.from(table), @joins_values) && @join_dependency)
        end

        def select_visitor
          Visitors::SelectVisitor.new(
            Contexts::JoinDependencyContext.new(join_dependency)
          )
        end

        def predicate_visitor
          Visitors::PredicateVisitor.new(
            Contexts::JoinDependencyContext.new(join_dependency)
          )
        end

        def order_visitor
          Visitors::OrderVisitor.new(
            Contexts::JoinDependencyContext.new(join_dependency)
          )
        end

        def build_arel
          arel = table.from table

          build_join_dependency(arel, @joins_values) unless @joins_values.empty?

          predicate_viz = predicate_visitor

          collapse_wheres(arel, predicate_viz.accept((@where_values - ['']).uniq))

          arel.having(*predicate_viz.accept(@having_values.uniq.reject{|h| h.blank?})) unless @having_values.empty?

          arel.take(connection.sanitize_limit(@limit_value)) if @limit_value
          arel.skip(@offset_value) if @offset_value

          arel.group(*@group_values.uniq.reject{|g| g.blank?}) unless @group_values.empty?

          unless @order_values.empty?
            order_viz = order_visitor
            arel.order(*order_viz.accept(@order_values.uniq.reject{|o| o.blank?}))
          end

          build_select(arel, select_visitor.accept(@select_values.uniq))

          arel.from(@from_value) if @from_value
          arel.lock(@lock_value) if @lock_value

          arel
        end

        def build_join_dependency(manager, joins)
          buckets = joins.group_by do |join|
            case join
            when String
              'string_join'
            when Hash, Symbol, Array, MetaWhere::Nodes::Join
              'association_join'
            when JoinAssociation
              'stashed_join'
            when Arel::Nodes::Join
              'join_node'
            else
              raise 'unknown class: %s' % join.class.name
            end
          end

          association_joins         = buckets['association_join'] || []
          stashed_association_joins = buckets['stashed_join'] || []
          join_nodes                = buckets['join_node'] || []
          string_joins              = (buckets['string_join'] || []).map { |x|
            x.strip
          }.uniq

          join_list = custom_join_ast(manager, string_joins)

          # All of this duplication just to add
          self.join_dependency = JoinDependency.new(
            @klass,
            association_joins,
            join_list
          )

          join_nodes.each do |join|
            join_dependency.table_aliases[join.left.name.downcase] = 1
          end

          join_dependency.graft(*stashed_association_joins)

          @implicit_readonly = true unless association_joins.empty? && stashed_association_joins.empty?

          # FIXME: refactor this to build an AST
          join_dependency.join_associations.each do |association|
            association.join_to(manager)
          end

          manager.join_sources.concat join_nodes.uniq
          manager.join_sources.concat join_list

          manager
        end

        def select(value = Proc.new)
          if block_given? && Proc === value
            if value.arity > 0
              to_a.select {|*block_args| value.call(*block_args)}
            else
              relation = clone
              relation.select_values += Array.wrap(Builders::StubBuilder.build &value)
              relation
            end
          else
            super
          end
        end

        def where(opts = Proc.new, *rest)
          if block_given? && Proc === opts
            super(Builders::StubBuilder.build &opts)
          else
            super
          end
        end

        def build_where(opts, other = [])
          case opts
          when String, Array
            super
          else
            [opts, *other].map do |arg|
              case arg
              when Array
                @klass.send(:sanitize_sql, arg)
              when Hash
                @klass.send(:expand_hash_conditions_for_aggregates, arg)
              else
                arg
              end
            end
          end
        end

        def order(*args)
          if block_given? && args.empty?
            super(Builders::StubBuilder.build &Proc.new)
          else
            super
          end
        end

        def joins(*args)
          if block_given? && args.empty?
            super(Builders::StubBuilder.build &Proc.new)
          else
            super
          end
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
            arel.where(test)
          end

          (wheres - binaries).each do |where|
            where = Arel.sql(where) if String === where
            arel.where(Arel::Nodes::Grouping.new(where))
          end
        end

        def find_equality_predicates(nodes)
          nodes.map { |node|
            case node
            when Arel::Nodes::Equality
              node
            when Arel::Nodes::Grouping
              find_equality_predicates(node.expr)
            when Arel::Nodes::And
              find_equality_predicates(node.children)
            else
              nil
            end
          }.compact.flatten
        end

        # Simulate the logic that occurs in #to_a
        #
        # This will let us get a dump of the SQL that will be run against the DB for debug
        # purposes without actually running the query.
        def debug_sql
          if eager_loading?
            including = (@eager_load_values + @includes_values).uniq
            join_dependency = JoinDependency.new(@klass, including, [])
            construct_relation_for_association_find(join_dependency).to_sql
          else
            arel.to_sql
          end
        end

        ### ZOMG ALIAS_METHOD_CHAIN IS BELOW. HIDE YOUR EYES!
        # ...
        # ...
        # ...
        # Since you're still looking, let me explain this horrible
        # transgression you see before you.
        # You see, Relation#where_values is defined on the
        # ActiveRecord::Relation class. Since it's defined there, but
        # I would very much like to modify its behavior, I have three
        # choices.
        #
        # 1. Inherit from ActiveRecord::Relation in a MetaWhere::Relation
        #    class, and make an attempt to usurp all of the various calls
        #    to methods on ActiveRecord::Relation by doing some really
        #    evil stuff with constant reassignment, all for the sake of
        #    being able to use super().
        #
        # 2. Submit a patch to Rails core, breaking this method off into
        #    another module, all for my own selfish desire to use super()
        #    while mucking about in Rails internals.
        #
        # 3. Use alias_method_chain, and say 10 hail Hanssons as penance.
        #
        # I opted to go with #3. Except for the hail Hansson thing.
        # Unless you're DHH, in which case, I totally said them.

        def self.included(base)
          base.class_eval do
            alias_method_chain :where_values_hash, :metawhere
          end
        end

        def where_values_hash_with_metawhere
          equalities = find_equality_predicates(predicate_visitor.accept(@where_values))

          Hash[equalities.map { |where| [where.left.name, where.right] }]
        end

      end
    end
  end
end