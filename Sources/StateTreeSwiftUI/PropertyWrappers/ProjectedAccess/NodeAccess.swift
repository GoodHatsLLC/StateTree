@_spi(Implementation) import StateTree
import SwiftUI
import TreeActor

// MARK: - NodeAccess

// FIXME: dedupe RouterAccess & NodeAccess. Move common into StateTreeAccess.
@dynamicMemberLookup
public protocol NodeAccess<N> {
  associatedtype N: Node
  @_spi(Implementation) var scope: NodeScope<N> { get }
}

extension NodeAccess {

  @TreeActor
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

  @TreeActor
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

  @TreeActor
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

  @TreeActor
  public subscript<Child: Node>(dynamicMember dynamicMember: KeyPath<N, Route<ListRouter<Child>>>)
    -> ListRouterAccess<Child>
  {
    get {
      let route = scope.node[keyPath: dynamicMember]
      return ListRouterAccess(route: route)
    }
    nonmutating set { }
  }

  @TreeActor
  public subscript<T>(dynamicMember dynamicMember: KeyPath<N, Projection<T>>) -> Binding<T> {
    get {
      scope.node[keyPath: dynamicMember].binding()
    }
    nonmutating set { }
  }

  public subscript<T>(dynamicMember dynamicMember: WritableKeyPath<N, T>) -> Binding<T> {
    Binding {
      scope.node[keyPath: dynamicMember]
    } set: { value in
      // This copy avoids an exclusive access error as the eventual
      // update calls use node.rules.
      var node = scope.node
      node[keyPath: dynamicMember] = value
    }
  }

}
