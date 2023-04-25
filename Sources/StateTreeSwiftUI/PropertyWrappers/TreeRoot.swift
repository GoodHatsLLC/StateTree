import Disposable
@_spi(Implementation) import StateTree
import StateTreePlayback
import SwiftUI

@propertyWrapper
@dynamicMemberLookup
public struct TreeRoot<N: Node>: DynamicProperty, NodeAccess {

  // MARK: Lifecycle

  public init(
    wrappedValue: N
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

  @_spi(Implementation) public var scope: NodeScope<N> {
    try! observed.tree.assume.root
  }

  @_spi(Implementation) public var nid: NodeID {
    try! observed.tree.assume.root.nid
  }

  public var wrappedValue: N {
    try! observed.tree.assume.root.node
  }

  public var root: TreeNode<N> {
    TreeNode(scope: scope)
  }

  public var projectedValue: Self {
    self
  }

  public func tree() -> Tree<N> {
    observed.tree
  }

  // MARK: Internal

  @StateObject var observed: ObservableRoot<N>

  // MARK: Private

  @State private var handle: TreeHandle<N>.StopHandle
}
