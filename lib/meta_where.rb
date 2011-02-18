require 'meta_where/configuration'

module MetaWhere
  extend Configuration
end

require 'meta_where/nodes'
require 'meta_where/dsl'
require 'meta_where/visitors'
require 'meta_where/adapters/active_record'

MetaWhere.setup_default_aliases!