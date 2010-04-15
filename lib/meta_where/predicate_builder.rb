module MetaWhere
  module PredicateBuilder
    extend ActiveSupport::Concern

    included do
      alias_method_chain :build_from_hash, :metawhere
    end
    
    def build_from_hash_with_metawhere(attributes, default_table)
      predicates = attributes.map do |column, value|
        table = default_table

        if value.is_a?(Hash)
          table = Arel::Table.new(column, :engine => @engine)
          build_from_hash(value, table)
        elsif value.is_a?(Array) && value.all? {|v| v.is_a?(MetaWhere::Condition)}
          value.map {|val| build_from_condition(val, table)}
        else
          if column.is_a?(MetaWhere::Column)
            method = column.method
            column = column.column
          else
            column = column.to_s
            method = method_from_value(value)
          end

          if column.include?('.')
            table_name, column = column.split('.', 2)
            table = Arel::Table.new(table_name, :engine => @engine)
          end

          unless attribute = table[column]
            raise ::ActiveRecord::StatementInvalid, "No attribute named `#{column}` exists for table `#{table.name}`"
          end
          
          unless valid_comparison_method?(method)
            raise ::ActiveRecord::StatementInvalid, "No comparison method named `#{method}` exists for column `#{column}`"
          end

          attribute.send(method, *args_for_predicate(method.to_s, value))
        end
      end

      predicates.flatten
    end
    
    def build_from_condition(condition, table)
      unless attribute = table[condition.column]
        raise ::ActiveRecord::StatementInvalid, "No attribute named `#{column}` exists for table `#{table.name}`"
      end
      
      unless valid_comparison_method?(condition.method)
        raise ::ActiveRecord::StatementInvalid, "No comparison method named `#{condition.method}` exists for column `#{column}`"
      end
      attribute.send(condition.method, *args_for_predicate(condition.method.to_s, condition.value))
    end
    
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
      Arel::Attribute::Predications.instance_methods.map(&:to_s).include?(method.to_s)
    end
    
  end
end