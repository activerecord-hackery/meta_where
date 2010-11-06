module MetaWhere
  module JoinDependency

    def self.included(base)
      base.class_eval do
        alias_method_chain :build, :metawhere
      end
    end

    class BaseMismatchError < StandardError; end
    class ConfigurationError < StandardError; end
    class AssociationNotFoundError < StandardError; end

    def build_with_metawhere(associations, parent = nil, join_type = Arel::Nodes::InnerJoin)
      if MetaWhere::JoinType === associations
        parent||= @joins.last
        reflection = parent.reflections[associations.name] or
          raise AssociationNotFoundError, "Association named '#{ associations.name }' was not found; perhaps you misspelled it?"
        unless association = find_join_association(reflection, parent)
          @reflections << reflection
          association = build_join_association(reflection, parent)
          association.join_type = associations.join_type
          @joins << association
        end
        association
      else
        build_without_metawhere(associations, parent, join_type)
      end
    end
  end
end