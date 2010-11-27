module MetaWhere
  module BelongsToPolymorphicAssociation
    def self.included(base)
      base.class_eval do
        alias_method_chain :conditions, :metawhere
        alias :sql_conditions :conditions_with_metawhere
      end
    end

    # How does this even work in core? Oh, nevermind, it doesn't. Patch submitted. :)
    def conditions_with_metawhere
      @conditions ||= interpolate_sql(association_class.send(:sanitize_sql, @reflection.options[:conditions])) if @reflection.options[:conditions]
    end

  end
end