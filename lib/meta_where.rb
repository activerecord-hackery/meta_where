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

  Constants::PREDICATE_ALIASES.each do |original, aliases|
    aliases.each do |aliaz|
      alias_predicate aliaz, original
    end
  end

end

require 'meta_where/nodes'
require 'meta_where/dsl'
require 'meta_where/visitors'
require 'meta_where/adapters/active_record'