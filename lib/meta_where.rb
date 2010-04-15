module MetaWhere
  METHOD_ALIASES = {
    'ne' => :noteq,
    'like' => :matches,
    'nlike' => :notmatches,
    'lte' => :lteq,
    'gte' => :gteq,
    'nin' => :notin
  }
end

require 'meta_where/column'
require 'meta_where/condition'
require 'core_ext/symbol'

if defined?(::Rails::Railtie)
  require 'meta_where/railtie'
end