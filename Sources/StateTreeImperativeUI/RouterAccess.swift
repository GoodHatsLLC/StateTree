@_spi(Implementation) import StateTree
import Utilities

// MARK: - RouterAccess

@dynamicMemberLookup
@TreeActor
public protocol RouterAccess {
  associatedtype NodeType: Node
  associatedtype Accessor: ScopeAccess where Accessor.NodeType == NodeType
  @_spi(Implementation) var access: Accessor { get }
}

extension RouterAccess {
  public subscript<SubNode: Node>(
    dynamicMember dynamicMember: KeyPath<NodeType, Route<SingleRouter<SubNode>>>
  ) -> Reporter<SubNode> {
    try! Reporter(scope: access.access(via: dynamicMember))
  }

  public subscript<SubNode: Node>(
    dynamicMember dynamicMember: KeyPath<NodeType, Route<MaybeSingleRouter<SubNode>>>
  ) -> Reporter<SubNode>? {
    try! access.access(via: dynamicMember).map { Reporter(scope: $0) }
  }

  public subscript<SubNodeA: Node, SubNodeB: Node>(
    dynamicMember dynamicMember: KeyPath<NodeType, Route<Union2Router<SubNodeA, SubNodeB>>>
  ) -> Union.Two<Reporter<SubNodeA>, Reporter<SubNodeB>> {
    try! access.access(via: dynamicMember)
      .map(
        a: { Reporter(scope: $0) },
        b: { Reporter(scope: $0) }
      )
  }

  public subscript<SubNodeA: Node, SubNodeB: Node>(
    dynamicMember dynamicMember: KeyPath<NodeType, Route<MaybeUnion2Router<SubNodeA, SubNodeB>>>
  ) -> Union.Two<Reporter<SubNodeA>, Reporter<SubNodeB>>? {
    try! access.access(via: dynamicMember)?
      .map(
        a: { Reporter(scope: $0) },
        b: { Reporter(scope: $0) }
      )
  }

  public subscript<SubNodeA: Node, SubNodeB: Node, SubNodeC: Node>(
    dynamicMember dynamicMember: KeyPath<
      NodeType,
      Route<Union3Router<SubNodeA, SubNodeB, SubNodeC>>
    >
  ) -> Union.Three<Reporter<SubNodeA>, Reporter<SubNodeB>, Reporter<SubNodeC>> {
    try! access.access(via: dynamicMember)
      .map(
        a: { Reporter(scope: $0) },
        b: { Reporter(scope: $0) },
        c: { Reporter(scope: $0) }
      )
  }

  public subscript<SubNodeA: Node, SubNodeB: Node, SubNodeC: Node>(
    dynamicMember dynamicMember: KeyPath<
      NodeType,
      Route<MaybeUnion3Router<SubNodeA, SubNodeB, SubNodeC>>
    >
  ) -> Union.Three<Reporter<SubNodeA>, Reporter<SubNodeB>, Reporter<SubNodeC>>? {
    try! access.access(via: dynamicMember)?
      .map(
        a: { Reporter(scope: $0) },
        b: { Reporter(scope: $0) },
        c: { Reporter(scope: $0) }
      )
  }

  public subscript<SubNode: Node>(
    dynamicMember dynamicMember: KeyPath<NodeType, Route<ListRouter<SubNode>>>
  ) -> DeferredList<Int, Reporter<SubNode>, Error> {
    let list = try! access.access(via: dynamicMember)
    return DeferredList(indices: list.startIndex ..< list.endIndex) { index in
      (try? list.element(at: index))
        .unwrappingResult()
        .map { scope in
          Reporter(scope: scope)
        }
        .mapError { $0 }
    }
  }
}
