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

require 'meta_where/column'
require 'meta_where/condition'
require 'meta_where/compound'
require 'core_ext/symbol'
require 'core_ext/hash'

if defined?(::Rails::Railtie)
  require 'meta_where/railtie'
end