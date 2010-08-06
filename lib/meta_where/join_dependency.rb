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

    def find_join_association(name_or_reflection, parent)
      case name_or_reflection
      when Symbol, String
        join_associations.detect {|j| (j.reflection.name == name_or_reflection.to_s.intern) && (j.parent == parent)}
      else
        join_associations.detect {|j| (j.reflection == name_or_reflection) && (j.parent == parent)}
      end
    end
  end
end