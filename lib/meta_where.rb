require 'meta_where/configuration'

module MetaWhere
  extend Configuration

  def self.evil_things
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = original_verbosity
  end
end

require 'meta_where/nodes'
require 'meta_where/dsl'
require 'meta_where/visitors'
require 'meta_where/adapters/active_record'

MetaWhere.setup_default_aliases!