require 'meta_where/adapters/active_record/relation'
require 'meta_where/adapters/active_record/join_dependency'

ActiveRecord::Relation.send :include, MetaWhere::Adapters::ActiveRecord::Relation
ActiveRecord::Associations::ClassMethods::JoinDependency.send :include, MetaWhere::Adapters::ActiveRecord::JoinDependency