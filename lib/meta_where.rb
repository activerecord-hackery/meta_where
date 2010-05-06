require 'arel'

module MetaWhere
  METHOD_ALIASES = {
    'ne' => :not_eq,
    'like' => :matches,
    'nlike' => :not_matches,
    'lte' => :lteq,
    'gte' => :gteq,
    'nin' => :not_in
  }
end

require 'active_record'
require 'meta_where/column'
require 'meta_where/condition'
require 'meta_where/compound'
require 'core_ext/symbol'
require 'core_ext/hash'
require 'meta_where/builder'
require 'meta_where/query_methods'
require 'meta_where/join_dependency'
ActiveRecord::Relation.send(:include, MetaWhere::QueryMethods)
ActiveRecord::Associations::ClassMethods::JoinDependency.send(:include, MetaWhere::JoinDependency)
ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase.send(:include, MetaWhere::JoinBase)
ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.send(:include, MetaWhere::JoinAssociation)