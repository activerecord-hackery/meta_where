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

    def build_with_metawhere(associations, parent = nil, join_type = Arel::Nodes::InnerJoin)

      if MetaWhere::JoinType === associations
        klass = associations.klass
        join_type = associations.join_type
        associations = associations.name
      end

      case associations
      when Symbol, String
        reflection = parent.reflections[associations.to_s.intern] or
          raise ConfigurationError, "Association named '#{ association }' was not found; perhaps you misspelled it?"
        unless (association = find_join_association(reflection, parent)) && (!klass || association.active_record == klass)
          @reflections << reflection
          if reflection.options[:polymorphic]
            association = build_polymorphic_join_association(reflection, parent, klass)
          else
            association = build_join_association(reflection, parent)
          end
          association.join_type = join_type
          @joins << association
        end
        association
      else
        build_without_metawhere(associations, parent, join_type)
      end
    end

    def find_join_association_with_metawhere(name_or_reflection, parent)
      if MetaWhere::JoinType === name_or_reflection
        join_associations.detect do |j|
          (j.reflection.name == name_or_reflection.name) &&
          (j.reflection.klass == name_or_reflection.klass) &&
          (j.parent == parent)
        end
      else
        find_join_association_without_metawhere(name_or_reflection, parent)
      end
    end

    def build_polymorphic_join_association(reflection, parent, klass)
      PolymorphicJoinAssociation.new(reflection, self, klass, parent)
    end
  end

  class PolymorphicJoinAssociation < ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation

    def initialize(reflection, join_dependency, polymorphic_class, parent = nil)
      reflection.check_validity!
      @active_record = polymorphic_class
      @cached_record = {}
      @join_dependency    = join_dependency
      @parent             = parent || join_dependency.join_base
      @reflection         = reflection.clone
      @reflection.instance_eval "def klass; #{polymorphic_class} end"
      @aliased_prefix     = "t#{ join_dependency.joins.size }"
      @parent_table_name  = @parent.active_record.table_name
      @aliased_table_name = aliased_table_name_for(table_name)
      @join               = nil
      @join_type          = Arel::Nodes::InnerJoin
    end

    def ==(other)
      other.class == self.class &&
      other.reflection == reflection &&
      other.active_record == active_record &&
      other.parent == parent
    end

    def association_join
      return @join if @join

      aliased_table = Arel::Table.new(table_name, :as => @aliased_table_name, :engine => arel_engine)
      parent_table = Arel::Table.new(parent.table_name, :as => parent.aliased_table_name, :engine => arel_engine)

      @join = [
        aliased_table[options[:primary_key] || reflection.klass.primary_key].eq(parent_table[options[:foreign_key] || reflection.primary_key_name]),
        parent_table[options[:foreign_type]].eq(active_record.base_class.name)
      ]

      unless klass.descends_from_active_record?
        sti_column = aliased_table[klass.inheritance_column]
        sti_condition = sti_column.eq(klass.sti_name)
        klass.descendants.each {|subclass| sti_condition = sti_condition.or(sti_column.eq(subclass.sti_name)) }

        @join << sti_condition
      end

      @join
    end
  end
end