#if !CUSTOM_ACTOR
@_spi(Implementation) import StateTree
import SwiftUI

// TODO: these separate implementations might be refactorable into one.
// This probably requires refactoring the RouterType.

// MARK: - SingleRouterAccess

@MainActor
struct SingleRouterAccess<R: SingleRouterType, Child: Node> where R.Value == Child {
  init(route: Route<R>) {
    self.route = route
  }

  private let route: Route<R>
}

extension SingleRouterAccess {
  func resolve<Child: Node>() -> NodeScope<Child>? {
    guard
      let (idSet, _) = route._routed,
      let id = idSet.ids.first,
      let anyScope = try? route.runtime?.getScope(for: id),
      let scope = anyScope.underlying as? NodeScope<Child>
    else {
      return nil
    }
    assert(idSet.ids.count == 1)
    return scope
  }
}

// MARK: - Union2RouterAccess

@MainActor
public struct Union2RouterAccess<A: Node, B: Node> {
  init(route: Route<UnionRouter<Union.Two<A, B>>>) {
    self.route = route
  }

  private let route: Route<UnionRouter<Union.Two<A, B>>>

  var anyScope: AnyScope? {
    guard
      let (idSet, _) = route._routed,
      let id = idSet.ids.first,
      let anyScope = try? route.runtime?.getScope(for: id)
    else {
      return nil
    }
    assert(idSet.ids.count == 1)
    return anyScope
  }

  public var a: TreeNode<A>? {
    (anyScope?.underlying as? NodeScope<A>)
      .map { TreeNode(scope: $0) }
  }

  public var b: TreeNode<B>? {
    (anyScope?.underlying as? NodeScope<B>)
      .map { TreeNode(scope: $0) }
  }
}

@MainActor
public struct Union3RouterAccess<A: Node, B: Node, C: Node> {

  // MARK: Lifecycle

  init(route: Route<UnionRouter<Union.Three<A, B, C>>>) {
    self.route = route
  }

  // MARK: Public

  public var a: TreeNode<A>? {
    (anyScope?.underlying as? NodeScope<A>)
      .map { TreeNode(scope: $0) }
  }

  public var b: TreeNode<B>? {
    (anyScope?.underlying as? NodeScope<B>)
      .map { TreeNode(scope: $0) }
  }

  public var c: TreeNode<C>? {
    (anyScope?.underlying as? NodeScope<C>)
      .map { TreeNode(scope: $0) }
  }

  // MARK: Internal

  var anyScope: AnyScope? {
    guard
      let (idSet, _) = route._routed,
      let id = idSet.ids.first,
      let anyScope = try? route.runtime?.getScope(for: id)
    else {
      return nil
    }
    assert(idSet.ids.count == 1)
    return anyScope
  }

  // MARK: Private

  private let route: Route<UnionRouter<Union.Three<A, B, C>>>

}

@MainActor
public struct ListRouterAccess<N: Node> where N: Identifiable {
  init(route: Route<ListRouter<N>>) {
    self.route = route
  }

  private let route: Route<ListRouter<N>>

  public func at(index: Int) -> TreeNode<N>? {
    self[index]
  }

  public subscript(_ index: Int) -> TreeNode<N>? {
    guard
      let (idSet, _) = route._routed,
      idSet.ids.count > index,
      let anyScope = try? route.runtime?.getScope(for: idSet.ids[index])
    else {
      return nil
    }
    return (anyScope.underlying as? NodeScope<N>)
      .map { TreeNode(scope: $0) }
  }
}

#endif
