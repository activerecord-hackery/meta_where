require 'active_record'

module MetaWhere
  # Because the AR::Associations namespace is insane
  JoinPart = ActiveRecord::Associations::ClassMethods::JoinDependency::JoinPart

  module Contexts
    class JoinDependencyContext
      attr_reader :base, :engine, :arel_visitor

      def initialize(join_dependency)
        @join_dependency = join_dependency
        @base = join_dependency.join_base
        @engine = @base.arel_engine
        @arel_visitor = Arel::Visitors.visitor_for @engine
        @default_table = Arel::Table.new(@base.table_name, :as => @base.aliased_table_name, :engine => @engine)
        @tables = Hash.new {|hash, key| hash[key] = get_table(key)}
      end

      def find(object, parent = base)
        if JoinPart === parent
          object = object.to_sym if String === object
          if Symbol === object
            @join_dependency.join_associations.detect { |j|
              j.reflection.name == object && j.parent == parent
            }
          else
            @join_dependency.join_associations.detect { |j|
              j.reflection == object && j.parent == parent
            }
          end
        else
          nil
        end
      end

      def contextualize(object)
        @tables[object]
      end

      private

      def get_table(object)
        if object.is_a?(Symbol)
          Arel::Table.new(object, :engine => @engine)
        elsif object.respond_to?(:aliased_table_name)
          Arel::Table.new(object.table_name, :as => object.aliased_table_name, :engine => @engine)
        else
          @default_table
        end
      end
    end
  end
end