require 'arel'

module MetaWhere
  NOT = Arel::Attribute::Predications.instance_methods.map(&:to_s).include?('noteq') ? :noteq : :not
  
  METHOD_ALIASES = {
    'ne' => NOT,
    'like' => :matches,
    'nlike' => :notmatches,
    'lte' => :lteq,
    'gte' => :gteq,
    'nin' => :notin
  }
end

require 'active_record'
require 'meta_where/column'
require 'meta_where/condition'
require 'meta_where/compound'
require 'core_ext/symbol'
require 'core_ext/hash'
require 'meta_where/predicate_builder'
require 'meta_where/query_methods'
require 'meta_where/join_dependency'
ActiveRecord::Relation.send(:include, MetaWhere::QueryMethods)
ActiveRecord::Associations::ClassMethods::JoinDependency.send(:include, MetaWhere::JoinDependency)
ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase.send(:include, MetaWhere::JoinBase)
ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.send(:include, MetaWhere::JoinAssociation)