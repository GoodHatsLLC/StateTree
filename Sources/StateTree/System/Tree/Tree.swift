import Behavior
import Disposable
import Emitter
import Foundation
import Intents
import TreeActor
import Utilities

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

  deinit {
    sessionSubject.value.state = .inactive
  }

  // MARK: Public

  public struct Events {

    // MARK: Public

    @_spi(Implementation) public var runtime: some Emitter<Runtime, Never> {
      sessionSubject
        .compactMap { session in
          switch session.state {
          case .created(let runtime): return runtime
          case .started(let runtime, _, _): return runtime
          default: return nil
          }
        }
    }

    /// A stream of notifications behavior events.
    @_spi(Implementation) public var behaviorEventEmitter: some Emitter<BehaviorEvent, Never> {
      runtime
        .flatMapLatest { runtime in
          runtime.behaviorTracker.behaviorEvents
        }
    }

    /// A stream of notifications updates emitted when nodes are updated.
    @_spi(Implementation) public var nodeEventEmitter: some Emitter<TreeEvent, Never> {
      runtime
        .flatMapLatest { runtime in
          runtime.updateEmitter
        }
    }

    /// A stream of notifications updates emitted when nodes are updated.
    @_spi(Implementation) public var treeEventEmitter: some Emitter<TreeEvent, Never> {
      runtime
        .flatMapLatest { runtime in
          runtime.updateEmitter.merge(
            runtime.behaviorEvents.map { $0.asTreeEvent() }
          )
        }
    }

    // MARK: Internal

    let sessionSubject: ValueSubject<Session, Never>

  }

  public struct Once {

    // MARK: Public

    /// The internal StateTree `Runtime` responsible for managing ``Node`` and ``TreeStateRecord``
    /// updates.
    @_spi(Implementation) public var runtime: Runtime
    @_spi(Implementation) public let root: NodeScope<N>

    /// Await inflight `Behavior` starts.
    ///
    /// `Behavior`s are created synchronously but often started asynchronously.
    /// Before starting behaviors can not read from a data source. In testing when
    /// mocking the data source it can be useful to wait for this ready state before
    /// simulating its side effects or providing its data.
    @discardableResult
    public func behaviorsStarted() async -> [BehaviorID] {
      let behaviors = runtime.behaviorTracker.behaviors
      var startedBehaviorIDs: [BehaviorID] = []
      for behavior in behaviors {
        await behavior.awaitReady()
        startedBehaviorIDs.append(behavior.id)
      }
      return startedBehaviorIDs
    }

    /// Await the `Result` states of all `Behaviors` registered on the tree.
    ///
    /// `Behavior`s often act asynchronously. This testing method allows
    /// waiting for their completion before verifying their effects.
    ///
    /// > Important: This method will not return until all behaviors tracked *at its call time* have
    /// resolved.
    @discardableResult
    public func behaviorsFinished() async -> [Behaviors.Result] {
      let behaviors = runtime.behaviorTracker.behaviors
      var resolutions: [Behaviors.Result] = []
      for behavior in behaviors {
        let resolution = await behavior.value
        resolutions.append(resolution)
      }
      return resolutions
    }

    public func result() async -> Result<TreeStateRecord, TreeError> {
      await result.value
    }

    // MARK: Internal

    let result: Async.Value<Result<TreeStateRecord, TreeError>>

  }

  public struct Active {

    // MARK: Lifecycle

    init(sessionSubject: ValueSubject<Session, Never>) throws {
      switch sessionSubject.value.state {
      case .started(runtime: let runtime, root: let root, result: _):
        self.runtime = runtime
        self.root = root
      default: throw TreeError(.inactive)
      }
    }

    // MARK: Public

    /// The runtime management system.
    @_spi(Implementation) public let runtime: Runtime

    /// The internal StateTree ``NodeScope`` backing the root ``Node``.
    @_spi(Implementation) public let root: NodeScope<N>

    /// The id of the root ``Node`` in the state tree.
    public var rootID: NodeID {
      root.nid
    }

    /// The root ``Node`` in the state tree.
    public var rootNode: N {
      root.node
    }

    /// Metadata about the current ``Tree`` and ``TreeLifetime``.
    public var info: StateTreeInfo {
      runtime.info
    }

    /// Update the tree's nodes to represent a new state.
    ///
    /// - Updates will often invalidate existing nodes.
    /// - Updates occur synchronously,
    ///
    /// > Note: This method is used as part of `StateTreePlayback` time travel debugging.
    @TreeActor
    public func restore(state: TreeStateRecord) throws {
      try runtime.set(state: state)
    }

    /// Save the current state of the tree.
    /// The created snapshot can be used to reset the tree to the saved state with ``set(state:)``.
    ///
    /// > Note: This method is used as part of `StateTreePlayback` time travel debugging.
    @TreeActor
    public func snapshot() throws -> TreeStateRecord {
      runtime.snapshot()
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

  }

  /// Await eventual session states via this property.
  public var once: Once {
    get async {
      while true {
        if let vals = await onceSessionSubject.compact().firstValue {
          return Once(runtime: vals.runtime, root: vals.root, result: vals.result)
        }
      }
    }
  }

  /// Access session events as they happen via this property.
  public var events: Events {
    Events(sessionSubject: sessionSubject)
  }

  /// Make state changing calls on the active tree via this property.
  public var assume: Active {
    get throws {
      try Active(sessionSubject: sessionSubject)
    }
  }

  public var isActive: Bool {
    switch sessionSubject.value.state {
    case .started:
      return true
    default:
      return false
    }
  }

  /// Start the tree.
  ///
  /// - Parameters:
  ///   - state: An optional previously recorded state to start the tree from.
  /// - Returns: An async closure which can be executed to return the eventual end result of tree
  /// execution.
  /// - Throws: A ``TreeError`` if the tree can't be started.
  @TreeActor
  @discardableResult
  public func start(from state: TreeStateRecord? = nil) throws -> TreeHandle<N> {
    let currentState = sessionSubject.value.state
    switch currentState {
    case .inactive: break
    case .ended: break
    case .started: throw TreeError(.alreadyStarted)
    case .created: throw TreeError(.alreadyStarted)
    }
    let runtime = Runtime(
      dependencies: dependencies,
      configuration: configuration
    )
    sessionSubject.value = Session(state: .created(runtime: runtime))
    do {
      let rootScope = try runtime.start(
        rootNode: inputRoot,
        initialState: state
      )
      let async = Async.Value<Result<TreeStateRecord, TreeError>>()
      sessionSubject.value.state = .started(runtime: runtime, root: rootScope, result: async)
      onceSessionSubject.value = (runtime: runtime, root: rootScope, result: async)
      return TreeHandle(
        asyncValue: async,
        stopFunc: { try self.stop() },
        root: rootScope
      )
    } catch {
      let error = TreeError(error)
      sessionSubject.value.state = .ended(result: .failure(error))
      throw error
    }
  }

  /// Stop the tree.
  ///
  /// - Returns: The state of the tree before stopping.
  /// - Throws: A ``TreeError`` if the tree is not in a stoppable state. (i.e. If it is not active.)
  @TreeActor
  @discardableResult
  public func stop() throws -> Result<TreeStateRecord, TreeError> {
    let currentState = sessionSubject.value.state
    let runtime: Runtime
    let asyncResult: Async.Value<Result<TreeStateRecord, TreeError>>?
    switch currentState {
    case .inactive: throw TreeError(.inactive)
    case .ended: throw TreeError(.inactive)
    case .started(runtime: let run, root: _, result: let res):
      runtime = run
      asyncResult = res
    case .created(runtime: let run):
      runtime = run
      asyncResult = nil
    }
    let snapshot = runtime.snapshot()
    runtime.stop()
    let result: Result<TreeStateRecord, TreeError> = .success(snapshot)
    if let asyncResult {
      Task.detached {
        await asyncResult.resolve(to: result)
      }
    }
    sessionSubject.value.state = .ended(result: result)
    return result
  }

  public func active<T>(_ access: (_ active: Active) throws -> T) rethrows -> T? {
    let active: Active
    do {
      active = try assume
    } catch {
      return nil
    }
    do {
      return try access(active)
    } catch {
      return nil
    }
  }

  // MARK: Internal

  struct Session: Equatable {
    let id = UUID()
    static var inactive: Session {
      .init(state: .inactive)
    }

    var state: State
    enum State: Equatable {
      case inactive
      case created(runtime: Runtime)
      case started(
        runtime: Runtime,
        root: NodeScope<N>,
        result: Async.Value<Result<TreeStateRecord, TreeError>>
      )
      case ended(result: Result<TreeStateRecord, TreeError>)
    }
  }

  // MARK: Private

  private let inputRoot: N
  private let dependencies: DependencyValues
  private let configuration: RuntimeConfiguration

  private let sessionSubject = ValueSubject<Session, Never>(.inactive)
  private let onceSessionSubject = ValueSubject<(
    runtime: Runtime,
    root: NodeScope<N>,
    result: Async.Value<Result<TreeStateRecord, TreeError>>
  )?, Never>(nil)

}
