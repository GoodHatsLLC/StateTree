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
    let route = scope.node[keyPath: dynamicMember]
    return SingleRouterAccess(route: route)
      .resolve()
      .map { TreeNode(scope: $0) }
  }

  public subscript<
    A: Node,
    B: Node
  >(dynamicMember dynamicMember: KeyPath<N, Route<UnionRouter<Union.Two<A, B>>>>)
    -> Union2RouterAccess<A, B>
  {
    let route = scope.node[keyPath: dynamicMember]
    return Union2RouterAccess(route: route)
  }

  public subscript<
    A: Node,
    B: Node,
    C: Node
  >(dynamicMember dynamicMember: KeyPath<N, Route<UnionRouter<Union.Three<A, B, C>>>>)
    -> Union3RouterAccess<A, B, C>
  {
    let route = scope.node[keyPath: dynamicMember]
    return Union3RouterAccess(route: route)
  }

  public subscript<Child: Node>(dynamicMember dynamicMember: KeyPath<N, Route<ListRouter<Child>>>)
    -> ListRouterAccess<Child>
  {
    let route = scope.node[keyPath: dynamicMember]
    return ListRouterAccess(route: route)
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<N, Projection<T>>) -> Binding<T> {
    scope.node[keyPath: dynamicMember].binding()
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<N, T>) -> T {
    scope.node[keyPath: dynamicMember]
  }

}
