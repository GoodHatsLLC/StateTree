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
    let root = ObservableRoot(root: wrappedValue)
    _observed = .init(wrappedValue: root)
  }

  // MARK: Public

  @_spi(Implementation) public var scope: NodeScope<N> {
    observed.life.root
  }

  public var tree: Tree {
    observed.life.tree
  }

  @_spi(Implementation) public var nid: NodeID {
    observed.life.root.nid
  }

  public var wrappedValue: N {
    observed.life.root.node
  }

  public var root: TreeNode<N> {
    TreeNode(scope: scope)
  }

  public var projectedValue: Self {
    self
  }

  public func life() -> TreeLifetime<N> {
    observed.life
  }

  public func player(frames: [StateFrame]) throws -> Player<N> {
    try observed.life.player(frames: frames)
  }

  public func recorder(frames: [StateFrame] = []) -> Recorder<N> {
    observed.life.recorder(frames: frames)
  }

  // MARK: Internal

  @StateObject var observed: ObservableRoot<N>

  // MARK: Private

  private var disposable: AnyDisposable?
}
