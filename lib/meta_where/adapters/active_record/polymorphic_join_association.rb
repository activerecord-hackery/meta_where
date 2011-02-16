module MetaWhere
  module Adapters
    module ActiveRecord

      class JoinAssociation < ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation

        def initialize(reflection, join_dependency, parent = nil, polymorphic_class = nil)
          if polymorphic_class && ::ActiveRecord::Base > polymorphic_class
            swapping_reflection_klass(reflection, polymorphic_class) do |reflection|
              super(reflection, join_dependency, parent)
            end
          else
            super(reflection, join_dependency, parent)
          end
        end

        def swapping_reflection_klass(reflection, klass)
          reflection = reflection.clone
          original_polymorphic = reflection.options.delete(:polymorphic)
          reflection.instance_variable_set(:@klass, klass)
          yield reflection
        ensure
          reflection.options[:polymorphic] = original_polymorphic
        end

        def join_belongs_to_to(relation)
          if options[:polymorphic]
            foreign_key = options[:foreign_key] || reflection.foreign_key
            foreign_type = options[:foreign_type] || reflection.foreign_type
            primary_key = options[:primary_key] || reflection.klass.primary_key

            join_target_table(
              relation,
              target_table[primary_key].eq(parent_table[foreign_key]).
              and(parent_table[foreign_type].eq(active_record.name))
            )
          else
            super
          end
        end

      end

    end
  end
end