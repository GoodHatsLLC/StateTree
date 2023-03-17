import Behaviors
import Disposable
import Utilities

// MARK: - NodeScope

@TreeActor
@_spi(Implementation)
public final class NodeScope<N: Node> {

  // MARK: Lifecycle

  init(
    _ node: InitializedNode<N>,
    dependencies: DependencyValues,
    depth: Int
  ) {
    self.activeRules = nil
    self.dependencies = dependencies
    self.depth = depth
    self.nid = node.id
    self.initialCapture = node.initialCapture
    self.initialRecord = node.nodeRecord
    self.node = node.node
    self.runtime = node.runtime
    self.cuid = node.node.cuid
    self.valueFieldDependencies = node.getValueDependencies()
  }

  // MARK: Public

  public var node: N
  public let nid: NodeID
  public let cuid: CUID?
  public let depth: Int
  public let dependencies: DependencyValues
  public let valueFieldDependencies: Set<FieldID>
  public let initialRecord: NodeRecord
  public let initialCapture: NodeCapture

  @_spi(Implementation) public var runtime: Runtime

  // MARK: Private

  private let stage = DisposableStage()
  private var activeRules: N.NodeRules?
  private var state: ScopeLifecycle = .shouldStart

  private var context: RuleContext {
    .init(
      runtime: runtime,
      scope: erase(),
      dependencies: dependencies,
      depth: depth
    )
  }

}

// MARK: Hashable

extension NodeScope: Hashable {
  public nonisolated static func == (lhs: NodeScope<N>, rhs: NodeScope<N>) -> Bool {
    lhs.nid == rhs.nid
  }

  public nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(nid)
  }
}

// MARK: ScopeType

extension NodeScope: ScopeType {

  // MARK: Public

  public var isActive: Bool { activeRules != nil }
  public var childScopes: [AnyScope] { runtime.childScopes(of: nid) }

  public func own(_ disposable: some Disposable) {
    if isActive {
      stage.stage(disposable)
    } else {
      disposable.dispose()
    }
  }

  public func erase() -> AnyScope {
    AnyScope(scope: self)
  }

  public func stop() throws {
    assert(activeRules != nil)
    activeRules = nil
    stage.dispose()
    disconnect()
  }

  // MARK: Private

  private func stopSubtree() throws {
    assert(activeRules != nil)
    try activeRules?.removeRule(with: context)
  }

  private func start() throws {
    assert(activeRules == nil)
    activeRules = node.rules
    try activeRules?.applyRule(with: context)
  }

  private func rebuild() throws {
    if activeRules == nil {
      try start()
    } else {
      try update()
    }
  }

  private func disconnect() {
    runtime.disconnect(scopeID: nid)
  }

  private func update() throws {
    assert(activeRules != nil)
    try activeRules?.updateRule(
      from: node.rules,
      with: context
    )
  }

  private func didUpdate() {
    assert(activeRules != nil)
    _ = activeRules?.act(
      for: .didUpdate,
      with: context
    )
  }

  private func willStop() {
    assert(activeRules != nil)
    _ = activeRules?.act(
      for: .willStop,
      with: context
    )
  }

  private func didStart() {
    assert(activeRules != nil)
    _ = activeRules?.act(
      for: .didStart,
      with: context
    )
  }

  private func handleIntents() {
    guard
      let intent = runtime.activeIntent,
      nid == intent.lastNodeID || ancestors.contains(intent.lastNodeID)
    else {
      return
    }
    assert(activeRules != nil)
    if
      let applicableResolutions = activeRules?
        .act(for: .handleIntent(intent.intent), with: context)
        .intentResolutions
        .filter(\.isApplicable),
      let firstResolution = applicableResolutions.first
    {
      if applicableResolutions.count > 1 {
        runtimeWarning("multiple applicable OnIntent handlers were found for an intent")
      }

      switch firstResolution {
      case .application(let act):
        runtime.recordIntentScopeDependency(nid)
        runtime.popIntentStep()
        act()
      case .pending:
        runtime.recordIntentScopeDependency(nid)
      case .inapplicable:
        assertionFailure("this state should be filtered out")
      }
    }
  }

}

extension NodeScope {

  // MARK: Public

  public var requiresReadying: Bool {
    state.requiresReadying
  }

  public var requiresFinishing: Bool {
    state.requiresFinishing
  }

  public var isStable: Bool {
    state.isStable
  }

  public var ancestors: [NodeID] {
    runtime.ancestors(of: nid) ?? []
  }

  public func applyIntent(_ intent: Intent) -> StepResolutionInternal {
    let resolutions = activeRules?
      .act(for: .handleIntent(intent), with: context)
      .intentResolutions ?? []
    let applicableResolutions = resolutions.filter(\.isApplicable)
    if applicableResolutions.count > 1 {
      runtimeWarning(
        "multiple intent handlers were applicable to the intent step. the first was used."
      )
    }
    let first = applicableResolutions.first ?? .inapplicable
    return first
  }

  public func stepTowardsReady() throws -> Bool {
    if let act = state.forward(scope: self) {
      return try act()
    } else {
      assertionFailure()
      return false
    }
  }

  public func stepTowardsFinished() throws -> Bool {
    if let act = state.finalize(scope: self) {
      return try act()
    } else {
      assertionFailure()
      return false
    }
  }

  public func markDirty(
    pending requirement: ExternalRequirement
  ) {
    state.mark(requirement: requirement)
  }

  // MARK: Private

  @TreeActor
  private enum ScopeLifecycle {

    // # Regular lifecycle stages

    // ## Stable cases.

    /// The scope is stable and does not need to be tracked.
    /// (Terminal 'readying' case.)
    case clean
    /// The scope has ended and does not need to be tracked.
    /// (Terminal 'finishing' case.)
    case finished

    // ## 'forwarding' cases resolved min-depth-first.

    /// The scope must start its lifecycle and then fire ``didStart`` events.
    case shouldStart
    /// The scope has started but must fire ``didStart`` events before transitioning to
    /// ``shouldHandleIntents``.
    case didStart

    /// The scope is dirty and must update.
    case shouldUpdate

    /// The scope must finally handle any pending applicable ``Intent`` before transitioning to
    /// ``shouldHandleIntents``.
    case shouldHandleIntents

    // ## 'finalizing' cases resolved max-depth-first.

    /// The scope must stop its sub-scopes and then continue stopping.
    case shouldPrepareStop
    /// The scope must fire ``willStop`` events and stop.
    case shouldNotifyStop
    /// The scope must stop.
    case shouldStop

    /// # Marker case for full tree rebuilds
    ///
    /// 'rebuild' is triggered only by apply(state:) as part of time-travel.
    /// The case is resolved min-depth-first as a 'forwarding' case.
    ///
    /// Scopes in 'rebuild' have 'clean' or 'shouldStart' underlying state but:
    /// - may not yet have routed based on it
    /// - may not yet exist as their parents have not routed to them.
    case rebuild

    // MARK: Public

    public mutating func forward(
      scope: NodeScope<N>
    ) -> (() throws -> Bool)? {
      assert(requiresReadying)
      switch self {
      case .shouldStart:
        self = .shouldHandleIntents
        return {
          try scope.start()
          scope.didStart()
          return false
        }
      case .shouldUpdate:
        self = .shouldHandleIntents
        return {
          try scope.update()
          scope.didUpdate()
          return false
        }
      case .shouldHandleIntents:
        self = .clean
        return {
          scope.handleIntents()
          return true
        }
      case .rebuild:
        self = .clean
        return {
          try scope.rebuild()
          return true
        }
      default: return nil
      }
    }

    public mutating func finalize(scope: NodeScope<N>) -> (() throws -> Bool)? {
      assert(requiresFinishing)
      switch self {
      case .shouldPrepareStop:
        self = .shouldNotifyStop
        return {
          try scope.stopSubtree()
          return false
        }
      case .shouldNotifyStop:
        self = .shouldStop
        return {
          scope.willStop()
          return false
        }
      case .shouldStop:
        self = .finished
        return {
          try scope.stop()
          return true
        }
      default: return nil
      }
    }

    // MARK: Internal

    var requiresReadying: Bool {
      switch self {
      case .shouldStart: true
      case .shouldUpdate: true
      case .shouldHandleIntents: true
      case .rebuild: true
      default: false
      }
    }

    var requiresFinishing: Bool {
      switch self {
      case .shouldStop: true
      case .shouldPrepareStop: true
      case .shouldNotifyStop: true
      case .finished: true
      default: false
      }
    }

    var isStable: Bool {
      switch self {
      case .clean: true
      case .finished: true
      default: false
      }
    }

    mutating func triggerUpdate() {
      switch self {
      case .clean:
        self = .shouldUpdate
      case .finished:
        self = .shouldUpdate
      case .shouldStart:
        return
      case .didStart:
        self = .shouldUpdate
      case .shouldUpdate:
        return
      case .shouldHandleIntents:
        self = .shouldUpdate
      case .shouldPrepareStop:
        return
      case .shouldNotifyStop:
        return
      case .shouldStop:
        return
      case .rebuild:
        return
      }
    }

    mutating func triggerFinalization() {
      switch self {
      case .clean:
        self = .shouldPrepareStop
      case .finished:
        return
      case .shouldStart:
        self = .finished
      case .didStart:
        self = .shouldPrepareStop
      case .shouldUpdate:
        self = .shouldPrepareStop
      case .shouldHandleIntents:
        self = .shouldPrepareStop
      case .shouldPrepareStop:
        return
      case .shouldNotifyStop:
        return
      case .shouldStop:
        return
      case .rebuild:
        self = .shouldPrepareStop
      }
    }

    mutating func triggerRebuild() {
      self = .rebuild
    }

    mutating func mark(requirement: ExternalRequirement) {
      if requirement == .stop {
        triggerFinalization()
      } else if requirement == .update {
        triggerUpdate()
      } else if requirement == .rebuild {
        triggerRebuild()
      } else {
        assertionFailure("scope-dirtying logic failure")
      }
    }

  }

}

extension NodeScope {

  public var record: NodeRecord {
    runtime
      .getRecord(nid) ?? initialRecord
  }

}
