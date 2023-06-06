// @_spi(Implementation) import StateTree
// import Utilities
//
//// MARK: - NodeAccess
//
// @dynamicMemberLookup
// @TreeActor
// public protocol NodeAccess {
//  associatedtype NodeType: Node
//  @_spi(Implementation) var scope: NodeScope<NodeType> { get }
// }
//
// extension NodeAccess {
//
//  // MARK: Public
//
//  @_disfavoredOverload
//  public subscript<Value>(
//    dynamicMember dynamicMember: KeyPath<NodeType, Value>
//  )
//    -> Value
//  {
//    node[keyPath: dynamicMember]
//  }
//
//  @_disfavoredOverload
//  public subscript<Value>(
//    dynamicMember dynamicMember: WritableKeyPath<NodeType, Value>
//  )
//    -> Value
//  {
//    get {
//      node[keyPath: dynamicMember]
//    }
//    nonmutating set {
//      node[keyPath: dynamicMember] = newValue
//    }
//  }
//
//  // MARK: Internal
//
//  var node: NodeType {
//    get { scope.node }
//    nonmutating set {
//      var node = node
//      node = newValue
//      runtimeWarning(
//        "attempting to write to unmanaged node components. this won't be reflected. %@",
//        [String(describing: node)]
//      )
//    }
//  }
//
// }
