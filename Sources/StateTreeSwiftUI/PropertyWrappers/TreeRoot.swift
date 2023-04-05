import Disposable
@_spi(Implementation) import StateTree
import StateTreePlayback
import SwiftUI

@propertyWrapper
@dynamicMemberLookup
public struct TreeRoot<N: Node>: DynamicProperty, NodeAccess {

  // MARK: Lifecycle

  public init(
    tree: Tree = Tree.main,
    wrappedValue: N
  ) {
    do {
      let root = try ObservableRoot(tree: tree, root: wrappedValue)
      _observed = .init(wrappedValue: root)
    } catch {
      preconditionFailure(error.localizedDescription)
    }
  }

  // MARK: Public

  @_spi(Implementation) public var scope: NodeScope<N> {
    observed.life.root
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

  private var disposable: AutoDisposable?
}
