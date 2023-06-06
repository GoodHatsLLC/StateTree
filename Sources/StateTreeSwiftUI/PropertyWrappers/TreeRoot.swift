import Disposable
@_spi(Implementation) import StateTreeBase
import StateTreePlayback
import SwiftUI

@propertyWrapper
public struct TreeRoot<NodeType: Node>: DynamicProperty {

  // MARK: Lifecycle

  public init(
    state: TreeStateRecord,
    rootNode: NodeType,
    dependencies: DependencyValues = .defaults
  ) {
    let tree = Tree(root: rootNode, dependencies: dependencies)
    do {
      let handle = try tree.start(from: state).autostop()
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

  public init(
    wrappedValue: NodeType
  ) {
    let tree = Tree(root: wrappedValue, dependencies: .defaults)
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

  public var node: TreeNode<NodeType> {
    TreeNode(scope: scope)
  }

  public var projectedValue: Self {
    self
  }

  public var tree: Tree<NodeType> {
    observed.tree
  }

  // MARK: Internal

  @StateObject var observed: ObservableRoot<NodeType>

  // MARK: Private

  @State private var handle: TreeHandle<NodeType>.StopHandle
}
