import Intents
import TreeActor
import Utilities

// MARK: - UpdatableScope

/// This protocol collects methods used to progress a ``NodeScope`` through
/// its ``ScopeUpdateLifecycle`` in response to a state change made
/// in the ``Node`` tree.
///
/// A `scope's` progression through its change lifecycle is managed by a ``ChangeManager``
/// instance created to manage the runtime effects of a state change.
///
/// ``NodeScope``s representing ``Node``s are updated when:
/// 1. They have been started or stopped by another node.
/// 2. Their state ``Value`` fields have changed and their ``Rules`` application may change.
///   * e.g. They may route to different sub-nodes.
///   * e.g. An ``OnChange`` or ``OnUpdate`` rule might trigger.
/// 3. They contain ``Projection`` fields which reference state in another node which has been
///   updated, and so must also reevaluate their ``Rules``.
protocol UpdatableScope {
  var requiresReadying: Bool { get }
  var requiresFinishing: Bool { get }
  var isStable: Bool { get }
  func stop() throws
  func disconnectSendingNotification()
  func stopSubtree() throws
  func start() throws
  func update() throws
  func didUpdate()
  func willStop()
  func didStart()
  func handleIntents()
  func applyIntent(_ intent: Intent) -> IntentStepResolution
  func stepTowardsReady() throws -> Bool
  func stepTowardsFinished() throws -> Bool
  func markDirty(pending: ExternalRequirement)
  func sendUpdateEvent()
}

// MARK: - NodeScope + UpdatableScope

extension NodeScope: UpdatableScope {

  // MARK: Public

  @TreeActor public var requiresReadying: Bool {
    state.requiresReadying
  }

  @TreeActor public var requiresFinishing: Bool {
    state.requiresFinishing
  }

  @TreeActor public var isStable: Bool {
    state.isStable
  }

  @TreeActor
  public func disconnectSendingNotification() {
    runtime.disconnect(scopeID: nid)
    didUpdateSubject.finish()
  }

  // MARK: Internal

  @TreeActor
  func stop() throws {
    assert(activeRules != nil)
    activeRules = nil
    stage.dispose()
    // NOTE: The scope is still present in the runtime and
    // must disconnect and notify consumers.
  }

  @TreeActor
  func stopSubtree() throws {
    assert(activeRules != nil)
    try activeRules?.removeRule(with: context)
    try routerSet.apply()
  }

  @TreeActor
  func start() throws {
    assert(activeRules == nil)
    activeRules = node.rules
    try activeRules?.applyRule(with: context)
    try routerSet.apply()
  }

  @TreeActor
  func update() throws {
    assert(activeRules != nil)
    try activeRules?.updateRule(
      from: node.rules,
      with: context
    )
    try routerSet.apply()
  }

  @TreeActor
  func didUpdate() {
    assert(activeRules != nil)
    _ = activeRules?.act(
      for: .didUpdate,
      with: context
    )
  }

  @TreeActor
  func willStop() {
    assert(activeRules != nil)
    _ = activeRules?.act(
      for: .willStop,
      with: context
    )
  }

  @TreeActor
  func didStart() {
    assert(activeRules != nil)
    _ = activeRules?.act(
      for: .didStart,
      with: context
    )
  }

  @TreeActor
  func handleIntents() {
    guard
      let intent = runtime.activeIntent,
      nid == intent.lastConsumerID || ancestors.contains(intent.lastConsumerID)
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

  @TreeActor
  func applyIntent(_ intent: Intent) -> IntentStepResolution {
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

  @TreeActor
  func stepTowardsReady() throws -> Bool {
    if let act = state.forward(scope: self) {
      return try act()
    } else {
      assertionFailure()
      return false
    }
  }

  @TreeActor
  func stepTowardsFinished() throws -> Bool {
    if let act = state.finalize(scope: self) {
      return try act()
    } else {
      assertionFailure()
      return false
    }
  }

  @TreeActor
  func markDirty(
    pending requirement: ExternalRequirement
  ) {
    switch requirement {
    case .stop:
      state.markRequiresStopping()
    case .update:
      state.markRequiresUpdating()
    }
  }

  func sendUpdateEvent() {
    didUpdateSubject.emit(value: ())
  }

}
