@_spi(Implementation) import StateTree
import SwiftUI

// MARK: - SingleRouterAccess

// TODO: these separate implementations might be refactorable into one.
// This probably requires refactoring the RouterType.

@MainActor
struct SingleRouterAccess<R: SingleRouterType, Child: Node> where R.Value == Child {
  init(route: Route<R>) {
    self.route = route
  }

  private let route: Route<R>
}

extension SingleRouterAccess {
  func resolve<Child: Node>() -> TreeNode<Child>? {
    guard
      let (idSet, _) = route._routed,
      let id = idSet.ids.first,
      let anyScope = try? route.runtime?.getScope(for: id),
      let scope = anyScope.underlying as? NodeScope<Child>
    else {
      return nil
    }
    assert(idSet.ids.count == 1)
    return .init(scope: scope)
  }
}

// MARK: - Union2RouterAccess

@MainActor
public struct Union2RouterAccess<A: Node, B: Node> {

  // MARK: Lifecycle

  init(route: Route<UnionRouter<Union.Two<A, B>>>) {
    self.route = route
  }

  // MARK: Public

  public var a: TreeNode<A>? {
    get {
      (anyScope?.underlying as? NodeScope<A>)
        .map { TreeNode(scope: $0) }
    }
    nonmutating set { }
  }

  public var b: TreeNode<B>? {
    get {
      (anyScope?.underlying as? NodeScope<B>)
        .map { TreeNode(scope: $0) }
    }
    nonmutating set { }
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

  private let route: Route<UnionRouter<Union.Two<A, B>>>

}

// MARK: - Union3RouterAccess

@MainActor
public struct Union3RouterAccess<A: Node, B: Node, C: Node> {

  // MARK: Lifecycle

  init(route: Route<UnionRouter<Union.Three<A, B, C>>>) {
    self.route = route
  }

  // MARK: Public

  public var a: TreeNode<A>? {
    get {
      (anyScope?.underlying as? NodeScope<A>)
        .map { TreeNode(scope: $0) }
    }
    nonmutating set { }
  }

  public var b: TreeNode<B>? {
    get {
      (anyScope?.underlying as? NodeScope<B>)
        .map { TreeNode(scope: $0) }
    } nonmutating set { }
  }

  public var c: TreeNode<C>? {
    get {
      (anyScope?.underlying as? NodeScope<C>)
        .map { TreeNode(scope: $0) }
    }
    nonmutating set { }
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

// MARK: - ListRouterAccess

@MainActor
public struct ListRouterAccess<N: Node> where N: Identifiable {
  init(route: Route<ListRouter<N>>) {
    self.route = route
  }

  private let route: Route<ListRouter<N>>

  public func at(index: Int) -> TreeNode<N>? {
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

  public var count: Int {
    if let (idSet, _) = route._routed {
      return idSet.ids.count
    } else {
      return 0
    }
  }
}

// MARK: Sequence

extension ListRouterAccess: Sequence {

  public typealias Element = TreeNode<N>
  public typealias Iterator = IndexingIterator<ListRouterAccess<N>>
  public typealias SubSequence = Slice<ListRouterAccess<N>>
}

// MARK: Collection

extension ListRouterAccess: Collection {
  public typealias Index = Int
  public typealias Indices = ArraySlice<Int>

  public var startIndex: Int {
    0
  }

  public var endIndex: Int {
    count
  }

  public var indices: ArraySlice<Int> {
    ArraySlice(0 ..< count)
  }

  public func index(
    after i: Int
  )
    -> Int
  {
    i + 1
  }

  public subscript(
    position: Int
  ) -> TreeNode<N> {
    at(index: position)!
  }
}

// MARK: BidirectionalCollection

extension ListRouterAccess: BidirectionalCollection {

  public func index(
    before i: Int
  )
    -> Int
  {
    i - 1
  }

  public func formIndex(
    before i: inout Int
  ) {
    i -= 1
  }
}

// MARK: RandomAccessCollection

extension ListRouterAccess: RandomAccessCollection { }
