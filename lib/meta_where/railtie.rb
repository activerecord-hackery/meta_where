require 'rails'
require 'meta_where'

module MetaWhere
  class Railtie < Rails::Railtie #:nodoc:
    initializer "meta_where.active_record" do |app|
      if defined? ::ActiveRecord
        require 'meta_where/predicate_builder'
        require 'meta_where/query_methods'
        ActiveRecord::PredicateBuilder.send(:include, MetaWhere::PredicateBuilder)
        ActiveRecord::Relation.send(:include, MetaWhere::QueryMethods)
      end
    end
  end
end