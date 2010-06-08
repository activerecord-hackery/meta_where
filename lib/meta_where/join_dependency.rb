module MetaWhere
  module JoinDependency
    extend ActiveSupport::Concern

    included do
      alias_method_chain :build, :metawhere
    end

    class BaseMismatchError < StandardError; end
    class ConfigurationError < StandardError; end
    class AssociationNotFoundError < StandardError; end

    def build_with_metawhere(associations, parent = nil, join_class = Arel::InnerJoin)
      parent ||= @joins.last
      case associations
      when Symbol, String
        reflection = parent.reflections[associations.to_s.intern] or
        raise AssociationNotFoundError, "Association named '#{ associations }' was not found; perhaps you misspelled it?"
        unless association = find_join_association(reflection, parent)
          @reflections << reflection
          association = (@joins << build_join_association(reflection, parent).with_join_class(join_class)).last
        end
        association
      when Array
        associations.each do |association|
          build(association, parent, join_class)
        end
      when Hash
        associations.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |name|
          association = build(name, parent, join_class)
          build(associations[name], association, join_class)
        end
      else
        raise ConfigurationError, associations.inspect
      end
    end

    def find_or_build_join_association(name, parent)
      unless parent.respond_to?(:reflections)
        raise ArgumentError, "Parent ('#{parent.class}') is not reflectable (must be JoinBase or JoinAssociation)"
      end

      raise ArgumentError, "#{name} is not a Symbol" unless name.is_a?(Symbol)

      build(name, parent)
    rescue AssociationNotFoundError
      nil
    end

    def find_join_association(name_or_reflection, parent)
      case name_or_reflection
      when Symbol, String
        join_associations.detect {|j| (j.reflection.name == name_or_reflection.to_s.intern) && (j.parent == parent)}
      else
        join_associations.detect {|j| (j.reflection == name_or_reflection) && (j.parent == parent)}
      end
    end

    def merge(other_join_dependency)
      if self.join_base == other_join_dependency.join_base
        self.graft(*other_join_dependency.join_associations)
      else
        raise BaseMismatchError, "Can't merge a join dependency with a different join base."
      end
    end
  end
end