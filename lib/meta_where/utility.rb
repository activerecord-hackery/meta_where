module MetaWhere
  module Utility
    private

    def args_for_predicate(method, value)
      value = [Array, ActiveRecord::Associations::AssociationCollection, ActiveRecord::Relation].include?(value.class) ? value.to_a : value
      if method =~ /_(any|all)$/ && value.is_a?(Array)
        value
      else
        [value]
      end
    end

    def method_from_value(value)
      case value
      when Array, Range, ActiveRecord::Associations::AssociationCollection, ActiveRecord::Relation
        :in
      else
        :eq
      end
    end

    def valid_comparison_method?(method)
      Arel::Attribute::PREDICATES.map(&:to_s).include?(method.to_s)
    end
  end
end