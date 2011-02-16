module MetaWhere
  module Adapters
    module ActiveRecord
      module JoinDependency

        def self.included(base)
          base.class_eval do
            alias_method_chain :build, :metawhere
          end
        end

        def build_with_metawhere(associations, parent = nil, join_type = Arel::InnerJoin)
          associations = associations.symbol if Nodes::Stub === associations
          if MetaWhere::Nodes::Join === associations
            parent ||= join_parts.last
            reflection = parent.reflections[associations.name] or
            raise ::ActiveRecord::ConfigurationError, "Association named '#{ associations.name }' was not found; perhaps you misspelled it?"
            unless join_association = find_join_association(reflection, parent)
              @reflections << reflection
              join_association = build_join_association(reflection, parent)
              join_association.join_type = associations.type
              @join_parts << join_association
              cache_joined_association(join_association)
            end
            join_association
          else
            build_without_metawhere(associations, parent, join_type)
          end
        end
      end

    end
  end
end