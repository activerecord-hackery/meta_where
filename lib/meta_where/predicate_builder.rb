require 'meta_where/utility'

module MetaWhere
  module PredicateBuilder
    extend ActiveSupport::Concern
    include MetaWhere::Utility

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
          table = Arel::Table.new(column, :engine => @engine)
          value.map {|val| val.to_predicate(table)}
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
    
  end
end