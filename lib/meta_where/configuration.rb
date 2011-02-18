module MetaWhere

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
  ].freeze

  DEFAULT_PREDICATE_ALIASES = {
    :matches        => [:like],
    :does_not_match => [:not_like],
    :lteq           => [:lte],
    :gteq           => [:gte]
  }.freeze

  module Configuration
    @@predicate_aliases = Hash.new {|h,k| h[k] = []}

    @@core_extensions_loaded = false

    def configure
      yield self
    end

    def alias_targets
      [Nodes::Function, Nodes::Stub, Nodes::Predicate] +
        (@@core_extensions_loaded ? [Symbol] : [])
    end

    def load_core_extensions!
      unless @@core_extensions_loaded
        require 'core_ext'
        @@core_extensions_loaded = true
        @@predicate_aliases.each do |original, aliases|
          aliases.each do |aliaz|
            alias_predicate_for_class aliaz, original, Symbol
          end
        end
      end
    end

    def setup_default_aliases!
      DEFAULT_PREDICATE_ALIASES.each do |original, aliases|
        aliases.each do |aliaz|
          alias_predicate aliaz, original
        end
      end
    end

    def alias_predicate(new_name, existing_name)
      raise ArgumentError, 'the existing name should be the base name, not an _any/_all variation' if existing_name.to_s =~ /(_any|_all)$/
      @@predicate_aliases[existing_name] |= [new_name]

      alias_targets.each do |klass|
        alias_predicate_for_class(new_name, existing_name, klass)
      end
    end

    def alias_predicate_for_class(new_name, existing_name, klass)
      if klass.method_defined? existing_name
        ['', '_any', '_all'].each do |suffix|
          klass.class_eval "alias :#{new_name}#{suffix} :#{existing_name}#{suffix} unless defined?(#{new_name}#{suffix})"
        end
      end
    end
  end
end