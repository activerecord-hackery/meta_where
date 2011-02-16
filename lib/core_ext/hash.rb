require 'meta_where/nodes/operators'

class Hash
  # Hashes are "acceptable" by PredicateVisitor, so they
  # can be treated like nodes for the purposes of and/or/not
  include MetaWhere::Nodes::Operators
end