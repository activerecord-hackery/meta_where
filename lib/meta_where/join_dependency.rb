module MetaWhere
  module JoinDependency
    extend ActiveSupport::Concern
    
    included do
      alias_method_chain :build, :metawhere
    end
    
    class BaseMismatchError < StandardError; end
    class ConfigurationError < StandardError; end
    class AssociationNotFoundError < StandardError; end
    
    def build_with_metawhere(associations, parent = nil, allow_duplicates = false)
      parent ||= @joins.last
      case associations
      when Symbol, String
        reflection = parent.reflections[associations.to_s.intern] or
        raise AssociationNotFoundError, "Association named '#{ associations }' was not found; perhaps you misspelled it?"
        if allow_duplicates || !(association = find_join_association(reflection, parent))
          @reflections << reflection
          association = (@joins << build_join_association(reflection, parent)).last
        end
        association
      when Array
        associations.each do |association|
          build(association, parent)
        end
      when Hash
        associations.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |name|
          association = build(name, parent)
          build(associations[name], association)
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
    
    def graft(*associations)
      associations.each do |association|
        join_associations.detect {|a| association == a} ||
        build(association.reflection.name, association.find_parent_in(self))
      end
      self
    end
    
    def count_aliases_from_table_joins(name)
      quoted_name = join_base.active_record.connection.quote_table_name(name.downcase)
      join_base.table_joins.blank? ? 0 :
        # Table names
        join_base.table_joins.to_s.downcase.scan(/join(?:\s+\w+)?\s+#{quoted_name}\son/).size +
        # Table aliases
        join_base.table_joins.to_s.downcase.scan(/join(?:\s+\w+)?\s+\S+\s+#{quoted_name}\son/).size
    end
  end
  
  module JoinBase
    extend ActiveSupport::Concern
    
    def ==(other)
      other.is_a?(JoinBase) &&
      other.active_record == active_record &&
      other.table_joins == table_joins
    end
  end
  
  module JoinAssociation
    extend ActiveSupport::Concern
    
    included do
      alias_method_chain :aliased_table_name_for, :metawhere
    end
    
    def ==(other)
      other.is_a?(JoinAssociation) &&
      other.reflection == reflection &&
      other.parent == parent
    end
    
    def find_parent_in(other_join_dependency)
      other_join_dependency.joins.detect do |join|
        self.parent == join
      end
    end
    
    def aliased_table_name_for_with_metawhere(name, suffix = nil)
      if @join_dependency.table_aliases[name].zero?
        @join_dependency.table_aliases[name] = @join_dependency.count_aliases_from_table_joins(name)
      end
      
      if !@join_dependency.table_aliases[name].zero? # We need an alias
        name = active_record.connection.table_alias_for "#{pluralize(reflection.name)}_#{parent_table_name}#{suffix}"
        @join_dependency.table_aliases[name] += 1
        if @join_dependency.table_aliases[name] == 1 # First time we've seen this name
          # Also need to count the aliases from the table_aliases to avoid incorrect count
          @join_dependency.table_aliases[name] += @join_dependency.count_aliases_from_table_joins(name)
        end
        table_index = @join_dependency.table_aliases[name]
        name = name[0..active_record.connection.table_alias_length-3] + "_#{table_index}" if table_index > 1
      else
        @join_dependency.table_aliases[name] += 1
      end
      
      name
    end
  end
end