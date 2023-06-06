@_spi(Implementation) import StateTreeBase
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
  ) -> TreeNode<SubNode> {
    try! TreeNode(scope: access.access(via: dynamicMember))
  }

  public subscript<SubNode: Node>(
    dynamicMember dynamicMember: KeyPath<NodeType, Route<MaybeSingleRouter<SubNode>>>
  ) -> TreeNode<SubNode>? {
    try! access.access(via: dynamicMember).map { TreeNode(scope: $0) }
  }

  public subscript<SubNodeA: Node, SubNodeB: Node>(
    dynamicMember dynamicMember: KeyPath<NodeType, Route<Union2Router<SubNodeA, SubNodeB>>>
  ) -> Union.Two<TreeNode<SubNodeA>, TreeNode<SubNodeB>> {
    try! access.access(via: dynamicMember)
      .map(
        a: { TreeNode(scope: $0) },
        b: { TreeNode(scope: $0) }
      )
  }

  public subscript<SubNodeA: Node, SubNodeB: Node>(
    dynamicMember dynamicMember: KeyPath<NodeType, Route<MaybeUnion2Router<SubNodeA, SubNodeB>>>
  ) -> Union.Two<TreeNode<SubNodeA>, TreeNode<SubNodeB>>? {
    try! access.access(via: dynamicMember)?
      .map(
        a: { TreeNode(scope: $0) },
        b: { TreeNode(scope: $0) }
      )
  }

  public subscript<SubNodeA: Node, SubNodeB: Node, SubNodeC: Node>(
    dynamicMember dynamicMember: KeyPath<
      NodeType,
      Route<Union3Router<SubNodeA, SubNodeB, SubNodeC>>
    >
  ) -> Union.Three<TreeNode<SubNodeA>, TreeNode<SubNodeB>, TreeNode<SubNodeC>> {
    try! access.access(via: dynamicMember)
      .map(
        a: { TreeNode(scope: $0) },
        b: { TreeNode(scope: $0) },
        c: { TreeNode(scope: $0) }
      )
  }

  public subscript<SubNodeA: Node, SubNodeB: Node, SubNodeC: Node>(
    dynamicMember dynamicMember: KeyPath<
      NodeType,
      Route<MaybeUnion3Router<SubNodeA, SubNodeB, SubNodeC>>
    >
  ) -> Union.Three<TreeNode<SubNodeA>, TreeNode<SubNodeB>, TreeNode<SubNodeC>>? {
    try! access.access(via: dynamicMember)?
      .map(
        a: { TreeNode(scope: $0) },
        b: { TreeNode(scope: $0) },
        c: { TreeNode(scope: $0) }
      )
  }

  public subscript<SubNode: Node>(
    dynamicMember dynamicMember: KeyPath<NodeType, Route<ListRouter<SubNode>>>
  ) -> DeferredList<Int, TreeNode<SubNode>, Error> {
    let list = try! access.access(via: dynamicMember)
    return DeferredList(indices: list.startIndex ..< list.endIndex) { index in
      (try? list.element(at: index))
        .unwrappingResult()
        .map { scope in
          TreeNode(scope: scope)
        }
        .mapError { $0 }
    }
  }
}
