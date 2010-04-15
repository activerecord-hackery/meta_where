require 'rails'
require 'meta_where'

module MetaWhere
  class Railtie < Rails::Railtie #:nodoc:
    initializer "meta_where.active_record" do |app|
      if defined? ::ActiveRecord
        require 'meta_where/predicate_builder'
        ActiveRecord::PredicateBuilder.send(:include, MetaWhere::PredicateBuilder)
      end
    end
  end
end