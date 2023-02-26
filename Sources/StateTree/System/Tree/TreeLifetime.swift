import Disposable
import Emitter

// MARK: - TreeLifetime

@TreeActor
public struct TreeLifetime<N: Node>: Disposable {

  // MARK: Lifecycle

  init(runtime: Runtime, root: NodeScope<N>, rootID: NodeID, disposable: AnyDisposable) {
    self.runtime = runtime
    self.root = root
    self.rootID = rootID
    self.disposable = disposable
  }

  // MARK: Public

  @_spi(Implementation) public let runtime: Runtime
  @_spi(Implementation) public let root: NodeScope<N>
  public let rootID: NodeID

  public var tree: Tree { runtime.tree }
  public var rootNode: N { root.node }
  public var updateEmitter: some Emitter<NodeID> { runtime.updateEmitter }
  public var _info: StateTreeInfo { runtime._info }

  public nonisolated func dispose() {
    disposable.dispose()
  }

  public func set(state: TreeStateRecord) throws {
    guard runtime.isActive
    else {
      runtimeWarning("The tree is inactive; the state can not be set.")
      throw InactiveTreeError()
    }
    try runtime.set(state: state)
  }

  /// Fetch the ``BehaviorResolution`` values for each ``Behavior`` that was run on the runtime.
  ///
  /// > Tip: This method can be used
  public func resolvedBehaviors() async -> [BehaviorResolution] {
    guard runtime.isActive
    else {
      return []
    }
    return await runtime
      .behaviorHost
      .resolvedBehaviors()
  }

  public func snapshot() -> TreeStateRecord {
    guard runtime.isActive
    else {
      runtimeWarning("The tree is inactive; snapshot records will be empty.")
      return .init()
    }
    return runtime.snapshot()
  }

  public func signal(intent: Intent) {
    guard runtime.isActive
    else {
      runtimeWarning("The tree is inactive; the intent could not be signalled.")
      return
    }
    do {
      try runtime.signal(intent: intent)
    } catch {
      assertionFailure(
        "the only known trigger for this failure should have been avoided by the preceding isActive check"
      )
    }
  }

  // MARK: Private

  private let disposable: AnyDisposable

}
