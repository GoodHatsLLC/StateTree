import Disposable

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
    self.id = node.id
    self.initialCapture = node.initialCapture
    self.initialRecord = node.nodeRecord
    self.node = node.node
    self.runtime = node.runtime
    self.uniqueIdentity = node.node.uniqueIdentity
    self.valueFieldDependencies = node.getValueDependencies()
  }

  // MARK: Public

  public var node: N
  public let id: NodeID
  public let uniqueIdentity: String?
  public let depth: Int
  public let dependencies: DependencyValues
  public let valueFieldDependencies: Set<FieldID>
  public let initialRecord: NodeRecord
  public let initialCapture: NodeCapture

  @_spi(Implementation) public var runtime: Runtime

  // MARK: Private

  private let stage = DisposableStage()
  private var behaviors: [PreparedBehavior] = []
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
    lhs.id == rhs.id
  }

  public nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: Scoped

extension NodeScope: Scoped {

  // MARK: Public

  public var isActive: Bool { activeRules != nil }
  public var childScopes: [AnyScope] { runtime.childScopes(of: id) }

  public var behaviorResolutions: [BehaviorResolution] {
    get async {
      var resolutions: [BehaviorResolution] = []
      for behavior in behaviors {
        let resolution = await behavior.resolution()
        resolutions.append(resolution)
      }
      return resolutions
    }
  }

  public func host<Behavior>(behavior: Behavior, input: Behavior.Input) -> Behavior.Action?
    where Behavior: BehaviorType
  {
    let action = runtime
      .behaviorHost
      .offerTestHooks(for: behavior, input: input)
    behaviors
      .append(
        behavior.prepare(input)
      )
    defer {
      if !isActive {
        behavior.dispose()
      }
    }
    return action
  }

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
    activeRules = nil
    for behavior in behaviors {
      behavior.dispose()
    }
    behaviors.removeAll()
    stage.dispose()
    disconnect()
  }

  // MARK: Private

  private func stopSubtree() throws {
    if var activeRules {
      try activeRules.removeRule(with: context)
      self.activeRules = activeRules
    }
  }

  private func start() throws {
    var rules = node.rules
    try rules.applyRule(with: context)
    activeRules = rules
  }

  private func rebuild() throws {
    if activeRules == nil {
      try start()
    } else {
      try update()
    }
  }

  private func disconnect() {
    runtime.disconnect(scopeID: id)
  }

  private func update() throws {
    assert(activeRules != nil)
    let new = node.rules
    try activeRules?.updateRule(
      from: new,
      with: context
    )
  }

  private func didUpdate() {
    assert(activeRules != nil)
    _ = activeRules?.act(
      for: .didUpdate,
      with: context
    ) ?? .init()
  }

  private func willStop() {
    assert(activeRules != nil)
    _ = activeRules?.act(
      for: .willStop,
      with: context
    ) ?? .init()
  }

  private func didStart() {
    assert(activeRules != nil)
    _ = activeRules?.act(
      for: .didStart,
      with: context
    ) ?? .init()
  }

  private func handleIntents() {
    guard
      let intent = runtime.activeIntent,
      id == intent.lastNodeID || ancestors.contains(intent.lastNodeID)
    else {
      return
    }
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
        runtime.recordIntentScopeDependency(id)
        runtime.popIntentStep()
        act()
      case .pending:
        runtime.recordIntentScopeDependency(id)
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

  public var isClean: Bool {
    state.isClean
  }

  public var isFinished: Bool {
    state.isFinished
  }

  public var ancestors: [NodeID] {
    runtime.ancestors(of: id) ?? []
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

  public func stepTowardsReady() throws {
    if let act = state.forward(scope: self) {
      try act()
    }
  }

  public func stepTowardsFinished() throws {
    if let act = state.finalize(scope: self) {
      try act()
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
    /// The scope has updated but must fire a ``didUpdate`` event and handle intents before
    /// transitioning to ``shouldHandleIntents``.
    case didUpdate

    /// The scope must finally handle any pending applicable ``Intent`` before transitioning to
    /// ``shouldHandleIntents``.
    case shouldHandleIntents
    /// The scope may now become ``clean`` and exit the queue.
    case shouldBecomeClean

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
    ) -> (() throws -> Void)? {
      assert(requiresReadying)
      switch self {
      case .shouldStart:
        self = .didStart
        return {
          try scope.start()
        }
      case .didStart:
        self = .shouldHandleIntents
        return {
          scope.didStart()
        }
      case .shouldUpdate:
        self = .didUpdate
        return {
          try scope.update()
        }
      case .didUpdate:
        self = .shouldHandleIntents
        return {
          scope.didUpdate()
        }
      case .shouldHandleIntents:
        self = .shouldBecomeClean
        return {
          scope.handleIntents()
        }
      case .shouldBecomeClean:
        self = .clean
        return nil
      case .rebuild:
        self = .clean
        return {
          try scope.rebuild()
        }
      default: return nil
      }
    }

    public mutating func finalize(scope: NodeScope<N>) -> (() throws -> Void)? {
      assert(requiresFinishing)
      switch self {
      case .shouldPrepareStop:
        self = .shouldNotifyStop
        return {
          try scope.stopSubtree()
        }
      case .shouldNotifyStop:
        self = .shouldStop
        return {
          scope.willStop()
        }
      case .shouldStop:
        self = .finished
        return {
          try scope.stop()
        }
      default: return nil
      }
    }

    // MARK: Internal

    var requiresReadying: Bool {
      switch self {
      case .shouldStart: return true
      case .didStart: return true
      case .shouldUpdate: return true
      case .didUpdate: return true
      case .shouldHandleIntents: return true
      case .shouldBecomeClean: return true
      case .clean: return true
      case .rebuild: return true
      default: return false
      }
    }

    var requiresFinishing: Bool {
      switch self {
      case .shouldStop: return true
      case .shouldPrepareStop: return true
      case .shouldNotifyStop: return true
      case .finished: return true
      default: return false
      }
    }

    var needsStart: Bool {
      switch self {
      case .shouldStart: return true
      case .didStart: return true
      default: return false
      }
    }

    var isClean: Bool {
      switch self {
      case .clean: return true
      default: return false
      }
    }

    var isFinished: Bool {
      switch self {
      case .finished: return true
      default: return false
      }
    }

    mutating func mark(requirement: ExternalRequirement) {
      if requiresFinishing {
        // stopping scopes must stop.
        return
      } else if requirement == .stop {
        if needsStart {
          // skip running any willStop notifications. minimise footprint.
          self = .finished
        } else {
          self = .shouldPrepareStop
        }
        return
      } else if requirement == .update {
        // must start before updating,
        // didStart is a superset of update.
        if !needsStart {
          self = .shouldUpdate
        }
      } else if requirement == .rebuild {
        self = .rebuild
      } else {
        assertionFailure("scope-dirtying logic failure")
      }
    }

  }

}

extension NodeScope {

  public var record: NodeRecord {
    runtime
      .getRecord(id) ?? initialRecord
  }

}
