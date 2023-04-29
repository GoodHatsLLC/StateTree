import Disposable
@_spi(Implementation) import StateTree
import StateTreePlayback
import SwiftUI

@propertyWrapper
@dynamicMemberLookup
public struct TreeRoot<NodeType: Node>: DynamicProperty, NodeAccess {

  // MARK: Lifecycle

  public init(
    wrappedValue: NodeType
  ) {
    let tree = Tree(root: wrappedValue, from: nil, dependencies: .defaults, configuration: .init())
    do {
      let handle = try tree.start().autostop()
      _handle = .init(wrappedValue: handle)
    } catch {
      preconditionFailure(
        """
        Could not start Tree.
        error: \(error.localizedDescription)
        """
      )
    }
    let root = ObservableRoot(tree: tree)
    _observed = .init(wrappedValue: root)
  }

  // MARK: Public

  @_spi(Implementation) public var scope: NodeScope<NodeType> {
    try! observed.tree.assume.root
  }

  @_spi(Implementation) public var nid: NodeID {
    try! observed.tree.assume.root.nid
  }

  public var wrappedValue: NodeType {
    try! observed.tree.assume.root.node
  }

  public var root: TreeNode<NodeType> {
    TreeNode(scope: scope)
  }

  public var projectedValue: Self {
    self
  }

  public func tree() -> Tree<N> {
    observed.tree
  }

  // MARK: Internal

  @StateObject var observed: ObservableRoot<NodeType>

  // MARK: Private

  @State private var handle: TreeHandle<NodeType>.StopHandle
}
