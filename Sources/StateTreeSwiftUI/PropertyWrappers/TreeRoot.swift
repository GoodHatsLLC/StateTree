#if !CUSTOM_ACTOR
@_spi(Implementation) import StateTree
import SwiftUI
import TimeTravel

@MainActor
@propertyWrapper
@dynamicMemberLookup
public struct TreeRoot<N: Node>: DynamicProperty, NodeAccess {

  // MARK: Lifecycle

  public init(
    wrappedValue: N
  ) {
    _state = .init(wrappedValue: RootNodeObject(root: wrappedValue))
  }

  // MARK: Public

  @_spi(Implementation) public var scope: NodeScope<N> {
    state.life.root
  }

  public var tree: Tree {
    state.life.tree
  }

  @_spi(Implementation) public var id: NodeID {
    state.life.root.id
  }

  public var wrappedValue: N {
    state.life.root.node
  }

  public var projectedValue: TreeRoot<N> {
    self
  }

  public func life() -> TreeLifetime<N> {
    state.life
  }

  public func player(frames: [StateFrame]) throws -> Player<N> {
    try state.life.player(frames: frames)
  }

  public func recorder(frames: [StateFrame] = []) -> Recorder<N> {
    state.life.recorder(frames: frames)
  }

  // MARK: Internal

  @StateObject var state: RootNodeObject<N>

}
#endif
