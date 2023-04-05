import Behaviors
import Disposable
import Emitter
import Foundation
import TreeActor
import Utilities

// MARK: - TreeLifetime

public struct TreeLifetime<N: Node>: Disposable {

  // MARK: Lifecycle

  init(runtime: Runtime, root: NodeScope<N>, rootID: NodeID, disposable: AutoDisposable) {
    self.runtime = runtime
    self.root = root
    self.rootID = rootID
    self.disposable = disposable
  }

  // MARK: Public

  /// The internal StateTree `Runtime` responsible for managing ``Node`` and ``TreeStateRecord``
  /// updates.
  ///
  /// > Note: This is exposed for UI integration library use, not for consumers.
  @_spi(Implementation) public let runtime: Runtime

  /// The internal StateTree ``NodeScope`` backing the root ``Node``.
  ///
  /// > Note: This is exposed for UI integration library use, not for consumers.
  @_spi(Implementation) public let root: NodeScope<N>

  /// The id of the root ``Node`` in the state tree.
  public let rootID: NodeID

  /// The root ``Node`` in the state tree.
  @TreeActor public var rootNode: N { root.node }

  /// A stream of notifications updates emitted when nodes are updated.
  @TreeActor public var updates: some Emitter<NodeChange> { runtime.updateEmitter }

  /// Metadata about the current ``Tree`` and ``TreeLifetime``.
  @TreeActor public var info: StateTreeInfo { runtime.info }

  /// Fetch the ``BehaviorResolution`` values for each ``Behavior`` that was run on the runtime.
  public var behaviorResolutions: [Behaviors.Resolved] {
    get async {
      await runtime
        .behaviorTracker
        .behaviorResolutions
    }
  }

  public nonisolated var isDisposed: Bool {
    disposable.isDisposed
  }

  /// Await inflight asynchronous `Behavior` subscriptions.
  ///
  /// `Behavior`s are created synchronously in calls including ``Scope/run(_:_:)-2i1vu`` and
  /// ``RunBehavior/init(_:_:_:id:behavior:onValue:onFinish:onFailure:)`` but
  /// can only read from their source or trigger side effects when their underlying data source
  /// subscription
  /// is invoked. This invocation happens concurrently.
  ///
  /// In production the underlying subscription will rarely need to be coordinated with a separate
  /// source and ``awaitReady(timeout:)`` will rarely be useful.
  ///
  /// In unit tests it may be convenient to trigger asynchronous behavior from another source. If
  /// doing
  /// so this method can be useful to wait until all behaviors in the state tree are ready to accept
  /// data.
  public func awaitReady(timeoutSeconds: Double? = nil) async throws {
    try await runtime.behaviorTracker.awaitReady(timeoutSeconds: timeoutSeconds)
  }

  public func awaitFinished(timeoutSeconds: Double? = nil) async throws {
    try await runtime.behaviorTracker.awaitFinished(timeoutSeconds: timeoutSeconds)
  }

  /// Shut down the tree removing all nodes and ending all behavior.
  public nonisolated func dispose() {
    disposable.dispose()
  }

  /// Update the tree's nodes to represent a new state.
  ///
  /// - Updates will often invalidate existing nodes.
  /// - Updates occur synchronously,
  ///
  /// > Note: This method is used as part of `StateTreePlayback` time travel debugging.
  @TreeActor
  public func set(state: TreeStateRecord) throws {
    guard runtime.isActive
    else {
      runtimeWarning("The tree is inactive; the state can not be set.")
      throw InactiveTreeError()
    }
    try runtime.set(state: state)
  }

  /// Save the current state of the tree.
  /// The created snapshot can be used to reset the tree to the saved state with ``set(state:)``.
  ///
  /// > Note: This method is used as part of `StateTreePlayback` time travel debugging.
  @TreeActor
  public func snapshot() -> TreeStateRecord {
    guard runtime.isActive
    else {
      runtimeWarning("The tree is inactive; snapshot records will be empty.")
      return .init()
    }
    return runtime.snapshot()
  }

  /// Fetch the `Resolved` states of all `Behaviors` triggered in the tree since starting.
  ///
  /// > Important: This method will not return until all behaviors tracked *at its call time* have
  /// resolved.
  public nonisolated func behaviorResolutions(timeoutSeconds: Double? = nil) async throws
    -> [Behaviors.Resolved]
  {
    try await runtime
      .behaviorTracker
      .behaviorResolutions(timeoutSeconds: timeoutSeconds)
  }

  /// Begin evaluating an ``Intent`` allowing each ``IntentStep`` to be processed in turn.
  ///
  /// - Intents are comprised of ``IntentStep``s which are evaluated from first to last.
  /// - Intents are evaluated, and their state changes enacted, synchronously when possible.
  /// - Intent steps are read via the ``OnIntent`` rule.
  /// - Steps will match a ``Node``'s ``OnIntent`` rule if:
  ///     1. The node is a descendent of the last matched node for the current intent.
  ///     2. No other node closer to the last matched node has already matched.
  ///     3. The rule accepts a type with a matching ``IntentStep/name`` field
  ///     4. The step's payload can be encoded to create an instance of the type.
  ///     5. The rule returns an ``IntentStepResolution/resolution(_:)``
  ///     (not an ``IntentStepResolution/pending``) payload.
  ///
  /// > Note: Only one intent can be active in the tree at once. Signalling an intent will cancel
  /// any previous unfinished one.
  @TreeActor
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

  private let disposable: AutoDisposable

}
