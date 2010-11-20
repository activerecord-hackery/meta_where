require 'meta_where/utility'

module MetaWhere
  module Visitors
    class Visitor
      include MetaWhere::Utility

      attr_reader :join_dependency, :tables

      def initialize(join_dependency)
        @join_dependency = join_dependency
        jb = join_dependency.join_base
        @engine = jb.arel_engine
        @default_table = Arel::Table.new(jb.table_name, :as => jb.aliased_table_name, :engine => @engine)
        @tables = Hash.new {|hash, key| hash[key] = get_table(key)}
      end

      def get_table(parent_or_table_name = nil)
        if parent_or_table_name.is_a?(Symbol)
          Arel::Table.new(parent_or_table_name, :engine => @engine)
        elsif parent_or_table_name.respond_to?(:aliased_table_name)
          Arel::Table.new(parent_or_table_name.table_name, :as => parent_or_table_name.aliased_table_name, :engine => @engine)
        else
          @default_table
        end
      end

      def accept(object, parent = nil)
        visit(object, parent)
      end

      def can_accept?(object)
        respond_to? DISPATCH[object.class]
      end

      private

      DISPATCH = Hash.new do |hash, klass|
        hash[klass] = "visit_#{klass.name.gsub('::', '_')}"
      end

      def visit(object, parent)
        send(DISPATCH[object.class], object, parent)
      end
    end
  end
end