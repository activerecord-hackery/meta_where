module MetaWhere
  METHOD_ALIASES = {
    'ne' => :not_eq,
    'like' => :matches,
    'not_matches' => :does_not_match,
    'nlike' => :does_not_match,
    'lte' => :lteq,
    'gte' => :gteq,
    'nin' => :not_in
  }

  PREDICATES = [
    :eq, :eq_any, :eq_all,
    :not_eq, :not_eq_any, :not_eq_all,
    :matches, :matches_any, :matches_all,
    :does_not_match, :does_not_match_any, :does_not_match_all,
    :lt, :lt_any, :lt_all,
    :lteq, :lteq_any, :lteq_all,
    :gt, :gt_any, :gt_all,
    :gteq, :gteq_any, :gteq_all,
    :in, :in_any, :in_all,
    :not_in, :not_in_any, :not_in_all
  ]

  def self.operator_overload!
    require 'core_ext/symbol_operators'
  end
end
require 'arel'
require 'active_record'
require 'active_support'
require 'meta_where/column'
require 'meta_where/condition'
require 'meta_where/compound'
require 'meta_where/function'
require 'meta_where/join_type'
require 'core_ext/symbol'
require 'core_ext/hash'
require 'meta_where/visitors/attribute'
require 'meta_where/visitors/predicate'
require 'meta_where/association_reflection'
require 'meta_where/belongs_to_polymorphic_association'
require 'meta_where/relation'
require 'meta_where/join_dependency'
ActiveRecord::Relation.send(:include, MetaWhere::Relation)
ActiveRecord::Reflection::AssociationReflection.send(:include, MetaWhere::AssociationReflection)
ActiveRecord::Associations::ClassMethods::JoinDependency.send(:include, MetaWhere::JoinDependency)
ActiveRecord::Associations::BelongsToPolymorphicAssociation.send(:include, MetaWhere::BelongsToPolymorphicAssociation)