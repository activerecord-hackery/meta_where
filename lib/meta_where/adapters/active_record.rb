require 'meta_where/adapters/active_record/relation'
require 'meta_where/adapters/active_record/join_dependency'
require 'meta_where/adapters/active_record/join_association'

ActiveRecord::Relation.send :include, MetaWhere::Adapters::ActiveRecord::Relation
ActiveRecord::Associations::JoinDependency.send :include, MetaWhere::Adapters::ActiveRecord::JoinDependency