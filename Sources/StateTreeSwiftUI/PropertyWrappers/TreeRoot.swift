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

  public func player(frames: [StateFrame]) throws -> Player<N> {
    try observed.tree.player(frames: frames)
  }

  public func recorder(frames: [StateFrame] = []) -> Recorder<N> {
    observed.tree.recorder(frames: frames)
  }

  // MARK: Internal

  @StateObject var observed: ObservableRoot<N>

  // MARK: Private

  private var disposable: AutoDisposable?
}
