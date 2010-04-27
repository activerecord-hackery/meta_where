require 'meta_where/utility'

module MetaWhere
  class PredicateBuilder
    include MetaWhere::Utility
    
    def initialize(join_dependency, autojoin = false)
      @join_dependency = join_dependency
      @engine = join_dependency.join_base.arel_engine
      @default_table = Arel::Table.new(join_dependency.join_base.table_name, :engine => @engine)
      @association_finder = autojoin ? :find_or_build_join_association : :find_join_association
    end
    
    def build_table(parent_or_table_name = nil)
      if parent_or_table_name.is_a?(Symbol)
        Arel::Table.new(parent_or_table_name, :engine => @engine)
      elsif parent_or_table_name.respond_to?(:aliased_table_name)
        Arel::Table.new(parent_or_table_name.table_name, :as => parent_or_table_name.aliased_table_name, :engine => @engine)
      else
        @default_table
      end
    end
    
    def build_from_hash(attributes, parent = nil)
      table = build_table(parent)
      predicates = attributes.map do |column, value|
        if value.is_a?(Hash)
          association = parent.is_a?(Symbol) ? nil : @join_dependency.send(@association_finder, column, parent)
          build_from_hash(value, association || column)
        elsif value.is_a?(Array) && value.all? {|v| v.is_a?(MetaWhere::Condition) || v.is_a?(Hash)}
          association = parent.is_a?(Symbol) ? nil : @join_dependency.send(@association_finder, column, parent)
          value.map {|val| val.to_predicate(self, association || column)}
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
            table = Arel::Table.new(table_name, :engine => parent.arel_engine)
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