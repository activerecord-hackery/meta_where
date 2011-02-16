module MetaWhere
  module Adapters
    module ActiveRecord
      module JoinDependency

        # Yes, I'm using alias_method_chain here. No, I don't feel too
        # bad about it. JoinDependency, or, to call it by its full proper
        # name, ::ActiveRecord::Associations::Classmethods::JoinDependency,
        # is one of the most "for internal use only" chunks of ActiveRecord,
        # as is obvious from the way it's hiddem way down there in the
        # ClassMethods module, and how it has more classes defined inside
        # its own class. Every time I find myself mucking around in here,
        # I feel a compelling urge to refactor the whole thing, and liberate
        # it from the depths of Associations::ClassMethods in the process.
        # It's a really handy class with a lot of cool stuff in it and I
        # wish it were more easily extensible without using a_m_c.
        #
        # Then I recognize the amount of actual effort that would take,
        # add an alias_method_chain, and pretend that associations work
        # by magic. It's worked out pretty well so far. Besides, I'm
        # pretty sure it bugs Jon Leighton as much as it does me, since
        # he's been spending so much quality time with AR::Associations
        # lately, and given the massive refactoring he's already
        # undertaken, he seems not to share my aversion to hard work. This
        # means that it will get fixed eventually. :)
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