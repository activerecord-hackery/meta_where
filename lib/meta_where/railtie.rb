require 'rails'
require 'meta_where'

module MetaWhere
  class Railtie < Rails::Railtie #:nodoc:
    initializer "meta_where.active_record" do |app|
      if defined? ::ActiveRecord
        require 'meta_where/predicate_builder'
        require 'meta_where/query_methods'
        require 'meta_where/join_dependency'
        #ActiveRecord::PredicateBuilder.send(:include, MetaWhere::PredicateBuilder)
        ActiveRecord::Relation.send(:include, MetaWhere::QueryMethods)
        ActiveRecord::Associations::ClassMethods::JoinDependency.send(:include, MetaWhere::JoinDependency)
        ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase.send(:include, MetaWhere::JoinBase)
        ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.send(:include, MetaWhere::JoinAssociation)
      end
    end
  end
end