module MetaWhere
  module JoinDependency

    def self.included(base)
      base.class_eval do
        alias_method_chain :build, :metawhere
        alias_method_chain :find_join_association, :metawhere
      end
    end

    class BaseMismatchError < StandardError; end
    class ConfigurationError < StandardError; end
    class AssociationNotFoundError < StandardError; end

    def build_with_metawhere(associations, parent = nil, join_type = Arel::InnerJoin)
      parent ||= join_parts.last
      if MetaWhere::JoinType === associations
        klass = associations.klass
        join_type = associations.join_type
        associations = associations.name
      end

      case associations
      when Symbol, String
        reflection = parent.reflections[associations.to_s.intern] or
          raise ConfigurationError, "Association named '#{ associations }' was not found; perhaps you misspelled it?"
        unless (association = find_join_association(reflection, parent)) && (!klass || association.active_record == klass)
          @reflections << reflection
          if reflection.options[:polymorphic]
            raise ArgumentError, "You can't create a polymorphic belongs_to join without specifying the polymorphic class!" unless klass
            association = PolymorphicJoinAssociation.new(reflection, self, klass, parent)
          else
            association = build_join_association(reflection, parent)
          end
          association.join_type = join_type
          @join_parts << association
          cache_joined_association(association)
        end
        association
      else
        build_without_metawhere(associations, parent, join_type)
      end
    end

    def find_join_association_with_metawhere(name_or_reflection, parent)
      case name_or_reflection
      when MetaWhere::JoinType
        join_associations.detect do |j|
          (j.reflection.name == name_or_reflection.name) &&
          (j.reflection.klass == name_or_reflection.klass) &&
          (j.parent == parent)
        end
      else
        case name_or_reflection
        when Symbol, String
          join_associations.detect {|j| (j.reflection.name == name_or_reflection.to_s.intern) && (j.parent == parent)}
        else
          join_associations.detect {|j| (j.reflection == name_or_reflection) && (j.parent == parent)}
        end
        #find_join_association_without_metawhere(name_or_reflection, parent)
      end
    end
  end

  class PolymorphicJoinAssociation < ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation

    def initialize(reflection, join_dependency, polymorphic_class, parent = nil)
      reflection.check_validity!
      @active_record = polymorphic_class
      @cached_record = {}
      @column_names_with_alias = nil
      @reflection      = reflection.clone
      @reflection.instance_variable_set :"@klass", polymorphic_class
      @join_dependency = join_dependency
      @parent          = parent
      @join_type       = Arel::InnerJoin
      @aliased_prefix  = "t#{ join_dependency.join_parts.size }"

      allocate_aliases
      @table = Arel::Table.new(
        table_name, :as => aliased_table_name, :engine => arel_engine
      )
    end


    def ==(other)
      other.class == self.class &&
      other.reflection == reflection &&
      other.active_record == active_record &&
      other.parent == parent
    end

    def join_belongs_to_to(relation)
      foreign_key = options[:foreign_key] || reflection.foreign_key
      foreign_type = options[:foreign_type] || reflection.foreign_type
      primary_key = options[:primary_key] || reflection.klass.primary_key
      join_target_table(
        relation,
        target_table[primary_key].eq(parent_table[foreign_key]).
        and(parent_table[foreign_type].eq(active_record.name))
      )
    end

  end
end