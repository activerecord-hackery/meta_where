require 'meta_where/utility'
require 'meta_where/visitors/predicate'
require 'meta_where/visitors/attribute'

module MetaWhere
  class Builder
    include MetaWhere::Utility
    include MetaWhere::Visitors::Predicate
    include MetaWhere::Visitors::Attribute

    attr_reader :join_dependency

    def initialize(join_dependency)
      @join_dependency = join_dependency
      @engine = join_dependency.join_base.arel_engine
      @default_table = Arel::Table.new(join_dependency.join_base.table_name, :engine => @engine)
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

    def build_predicates_from_hash(attributes, parent = nil)
      table = build_table(parent)
      predicates = attributes.map do |column, value|
        if value.is_a?(Hash)
          association = association_from_parent_and_column(parent, column)
          build_predicates_from_hash(value, association || column)
        elsif [MetaWhere::Condition, MetaWhere::And, MetaWhere::Or].include?(value.class)
          association = association_from_parent_and_column(parent, column)
          predicate_accept(value, association || column)
        elsif value.is_a?(Array) && !value.empty? && value.all? {|v| can_predicate?(v)}
          association = association_from_parent_and_column(parent, column)
          value.map {|val| predicate_accept(val, association || column)}
        else
          if column.is_a?(MetaWhere::Column)
            method = column.method
            column = column.column
          else
            method = method_from_value(value)
          end

          if [String, Symbol].include?(column.class) && column.to_s.include?('.')
            table_name, column = column.to_s.split('.', 2)
            table = Arel::Table.new(table_name, :engine => parent.arel_engine)
          end

          unless attribute = attribute_from_column_and_table(column, table)
            raise ::ActiveRecord::StatementInvalid, "No attribute named `#{column}` exists for table `#{table.name}`"
          end

          unless valid_comparison_method?(method)
            raise ::ActiveRecord::StatementInvalid, "No comparison method named `#{method}` exists for column `#{column}`"
          end

          attribute.send(method, args_for_predicate(value))
        end
      end

      predicates.flatten
    end

    def build_attributes_from_hash(attributes, parent = nil)
      table = build_table(parent)
      built_attributes = attributes.map do |column, value|
        if value.is_a?(Hash)
          association = association_from_parent_and_column(parent, column)
          build_attributes_from_hash(value, association || column)
        elsif value.is_a?(Array) && value.all? {|v| can_attribute?(v)}
          association = association_from_parent_and_column(parent, column)
          value.map {|val| self.attribute_accept(val, association || column)}
        else
          association = association_from_parent_and_column(parent, column)
          can_attribute?(value) ? self.attribute_accept(value, association || column) : value
        end
      end

      built_attributes.flatten
    end

    private

    def association_from_parent_and_column(parent, column)
      parent.is_a?(Symbol) ? nil : @join_dependency.send(:find_join_association, column, parent)
    end

  end
end
