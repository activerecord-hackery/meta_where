module MetaWhere
  module QueryMethods
    def build_where(*args)
      return if args.blank?

      opts = args.first
      if [String, Array].include?(opts.class)
        @klass.send(:sanitize_sql, args.size > 1 ? args : opts)
      else
        predicates = []
        builder = ActiveRecord::PredicateBuilder.new(table.engine)
        args.each do |arg|
          predicates += Array.wrap(
            case arg
            when Hash
              attributes = @klass.send(:expand_hash_conditions_for_aggregates, arg)
              builder.build_from_hash(attributes, table)
            when MetaWhere::Condition, MetaWhere::Compound
              arg.to_predicate(table)
            else
              opts
            end
          )
        end
        predicates
      end
    end
  end
end