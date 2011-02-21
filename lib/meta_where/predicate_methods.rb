require 'meta_where/predicate_methods/symbol'
require 'meta_where/predicate_methods/stub'
require 'meta_where/predicate_methods/predicate'
require 'meta_where/predicate_methods/function'

module MetaWhere
  module PredicateMethods

    def self.included(base)
      base.send :include, const_get(base.name.split(/::/)[-1].to_sym)
    end

    Constants::PREDICATES.each do |method_name|
      class_eval <<-RUBY
        def #{method_name}(value = :__undefined__)
          predicate :#{method_name}, value
        end
      RUBY
    end

  end
end