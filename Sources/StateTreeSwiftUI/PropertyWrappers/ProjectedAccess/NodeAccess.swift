@_spi(Implementation) import StateTree
import SwiftUI

// MARK: - NodeAccess

@MainActor
@dynamicMemberLookup
public protocol NodeAccess<N> {
  associatedtype N: Node
  @_spi(Implementation) var scope: NodeScope<N> { get }
}

extension NodeAccess {

  public subscript<R: SingleRouterType>(dynamicMember dynamicMember: KeyPath<N, Route<R>>)
    -> TreeNode<R.Value>? where R.Value: Node
  {
    get {
      let route = scope.node[keyPath: dynamicMember]
      return SingleRouterAccess(route: route)
        .resolve()
    }
    nonmutating set { }
  }

  public subscript<
    A: Node,
    B: Node
  >(dynamicMember dynamicMember: KeyPath<N, Route<UnionRouter<Union.Two<A, B>>>>)
    -> Union2RouterAccess<A, B>
  {
    get {
      let route = scope.node[keyPath: dynamicMember]
      return Union2RouterAccess(route: route)
    }
    nonmutating set { }
  }

  public subscript<
    A: Node,
    B: Node,
    C: Node
  >(dynamicMember dynamicMember: KeyPath<N, Route<UnionRouter<Union.Three<A, B, C>>>>)
    -> Union3RouterAccess<A, B, C>
  {
    get {
      let route = scope.node[keyPath: dynamicMember]
      return Union3RouterAccess(route: route)
    }
    nonmutating set { }
  }

  public subscript<Child: Node>(dynamicMember dynamicMember: KeyPath<N, Route<ListRouter<Child>>>)
    -> ListRouterAccess<Child>
  {
    get {
      let route = scope.node[keyPath: dynamicMember]
      return ListRouterAccess(route: route)
    }
    nonmutating set { }
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<N, Projection<T>>) -> Binding<T> {
    get {
      scope.node[keyPath: dynamicMember].binding()
    }
    nonmutating set { }
  }

  public subscript<T>(dynamicMember dynamicMember: WritableKeyPath<N, T>) -> T {
    get {
      scope.node[keyPath: dynamicMember]
    }
    nonmutating set {
      // This copy avoids an exclusive access error as the eventual
      // update calls use node.rules.
      var node = scope.node
      node[keyPath: dynamicMember] = newValue
//      scope.node = node
    }
  }

}
