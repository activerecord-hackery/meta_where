module MetaWhere
  class MetaWhereInAssociationError < StandardError; end

  module AssociationReflection

    def initialize(macro, name, options, active_record)
      super

      if options.has_key?(:conditions)
        ensure_no_metawhere_in_conditions(options[:conditions])
      end
    end

    private

    def ensure_no_metawhere_in_conditions(obj)
      case obj
      when Hash
        if obj.keys.grep(MetaWhere::Column).any?
          raise MetaWhereInAssociationError, <<END
The :#{name} association  has a MetaWhere::Column in its :conditions. \
If you actually needed to access conditions other than equality, then you most \
likely meant to set up a scope or method, instead. Associations only work with \
standard equality conditions, since they can be used to create records as well.
END
        end

        obj.values.each do |v|
          case v
          when MetaWhere::Condition, Array, Hash
            ensure_no_metawhere_in_conditions(v)
          end
        end
      when Array
        obj.each do |v|
          case v
          when MetaWhere::Condition, Array, Hash
            ensure_no_metawhere_in_conditions(v)
          end
        end
      when MetaWhere::Condition
        raise MetaWhereInAssociationError, <<END
The :#{name} association has a MetaWhere::Condition in its :conditions. \
If you actually needed to access conditions other than equality, then you most \
likely meant to set up a scope or method, instead. Associations only work with \
standard equality conditions, since they can be used to create records as well.
END
      end
    end
  end
end