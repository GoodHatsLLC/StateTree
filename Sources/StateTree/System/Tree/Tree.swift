import Behavior
import Disposable
import Emitter
import Foundation
import TreeActor
import Utilities

// MARK: - TreeError

public enum TreeError: Error, CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .alreadyStarted: return "The tree was already started."
    case .inactive: return "The tree is not active."
    case .wrapped(error: let error): return error.localizedDescription
    }
  }

  case alreadyStarted
  case inactive
  case wrapped(error: Error)
}

// MARK: - Tree

public final class Tree<N: Node> {

  // MARK: Lifecycle

  public init(
    root inputRoot: N,
    from _: TreeStateRecord? = nil,
    dependencies: DependencyValues = .defaults,
    configuration: RuntimeConfiguration = .init()
  ) {
    self.inputRoot = inputRoot
    self.dependencies = dependencies
    self.configuration = configuration
  }

  // MARK: Public

  /// The internal StateTree `Runtime` responsible for managing ``Node`` and ``TreeStateRecord``
  /// updates.
  @_spi(Implementation) public var runtime: Runtime {
    get throws {
      guard let runtime = state.runtimeSubject.value
      else {
        throw TreeError.inactive
      }
      return runtime
    }
  }

  /// The internal StateTree ``NodeScope`` backing the root ``Node``.
  @_spi(Implementation) @TreeActor public var root: NodeScope<N> {
    get throws {
      guard let scope = try runtime.root?.underlying as? NodeScope<N>
      else {
        throw TreeError.inactive
      }
      return scope
    }
  }

  /// The id of the root ``Node`` in the state tree.
  @TreeActor public var rootID: NodeID {
    get throws {
      try root.nid
    }
  }

  /// The root ``Node`` in the state tree.
  @TreeActor public var rootNode: N {
    get throws {
      try root.node
    }
  }

  /// A stream of notifications updates emitted when nodes are updated.
  @TreeActor public var updates: some Emitter<TreeEvent, Never> {
    runtimePublisher
      .flatMapLatest { $0.updateEmitter }
  }

  /// Metadata about the current ``Tree`` and ``TreeLifetime``.
  public var info: StateTreeInfo {
    get throws {
      try runtime.info
    }
  }

  /// Fetch the ``BehaviorResolution`` values for each ``Behavior`` that was run on the runtime.
  public var behaviorResolutions: [Behaviors.Resolved] {
    get async throws {
      try await runtime
        .behaviorTracker
        .behaviorResolutions
    }
  }

  @TreeActor
  @discardableResult
  public func start() throws -> () async -> Result<TreeStateRecord, TreeError> {
    if state.runtimeSubject.value != nil {
      throw TreeError.alreadyStarted
    }
    let runtime = Runtime(
      dependencies: dependencies,
      configuration: configuration
    )
    state.runtimeSubject.emit(value: runtime)
    do {
      state.rootScope = try runtime.start(rootNode: inputRoot)
    } catch {
      stop()
      throw TreeError.wrapped(error: error)
    }

    let async = Async.Value<Result<TreeStateRecord, TreeError>>()
    state.stopResult = async
    return {
      await async.value
    }
  }

  @TreeActor
  public func stop() {
    if let asyncResult = state.stopResult {
      let result: Result<TreeStateRecord, TreeError>
      if let snap = state.runtime?.snapshot() {
        result = .success(snap)
      } else {
        result = .failure(.inactive)
      }
      Task.detached {
        await asyncResult.resolve(to: result)
      }
    }
    state.runtimeSubject.value?.stop()
    state.runtimeSubject.emit(value: nil)
    state.rootScope = nil
    state.stopResult = nil
  }

  /// Await inflight `Behavior` starts.
  ///
  /// `Behavior`s are created synchronously but often started asynchronously.
  /// Before starting behaviors can not read from a data source. In testing when
  /// mocking the data source it can be useful to wait for this ready state before
  /// simulating its side effects or providing its data.
  public func awaitReady(timeoutSeconds: Double? = nil) async throws {
    try await runtime.behaviorTracker.awaitReady(timeoutSeconds: timeoutSeconds)
  }

  /// Await inflight `Behavior` finishes.
  ///
  /// `Behavior`s often act asynchronously. This testing method allows
  /// waiting for their completion before verifying their effects.
  public func awaitBehaviors(timeoutSeconds: Double? = nil) async throws {
    try await runtime.behaviorTracker.awaitBehaviors(timeoutSeconds: timeoutSeconds)
  }

  /// Update the tree's nodes to represent a new state.
  ///
  /// - Updates will often invalidate existing nodes.
  /// - Updates occur synchronously,
  ///
  /// > Note: This method is used as part of `StateTreePlayback` time travel debugging.
  @TreeActor
  public func set(state: TreeStateRecord) throws {
    try runtime.set(state: state)
  }

  /// Save the current state of the tree.
  /// The created snapshot can be used to reset the tree to the saved state with ``set(state:)``.
  ///
  /// > Note: This method is used as part of `StateTreePlayback` time travel debugging.
  @TreeActor
  public func snapshot() throws -> TreeStateRecord {
    try runtime.snapshot()
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
  public func signal(intent: Intent) throws {
    try runtime.signal(intent: intent)
  }

  // MARK: Internal

  struct State {
    var rootScope: NodeScope<N>?
    var stopResult: Async.Value<Result<TreeStateRecord, TreeError>>?
    let runtimeSubject = ValueSubject<Runtime?, Never>(nil)
    var runtimeEmitter: some Emitter<Runtime?, Never> {
      runtimeSubject
    }

    var runtime: Runtime? {
      runtimeSubject.value
    }
  }

  // MARK: Private

  private let inputRoot: N
  private let dependencies: DependencyValues
  private let configuration: RuntimeConfiguration

  private var state: State = .init()

  private var runtimePublisher: some Emitter<Runtime, Never> {
    state.runtimeSubject.compactMap(transformer: { $0 })
  }

}
