@_spi(Implementation) import Behavior
import Emitter
import Foundation
import HeapModule
import Intents
import TreeActor
import Utilities

// MARK: - Runtime

@TreeActor
@_spi(Implementation)
public final class Runtime: Equatable {

  // MARK: Lifecycle

  nonisolated init(
    treeID: UUID,
    dependencies: DependencyValues,
    configuration: RuntimeConfiguration
  ) {
    self.treeID = treeID
    self.dependencies = dependencies
    self.configuration = configuration
  }

  // MARK: Public

  public let treeID: UUID

  public nonisolated var updateEmitter: some Emitter<[TreeEvent], Never> {
    updateSubject
      .merge(behaviorTracker.behaviorEvents.map { [.behavior(event: $0)] })
  }

  public nonisolated static func == (lhs: Runtime, rhs: Runtime) -> Bool {
    lhs === rhs
  }

  // MARK: Internal

  let configuration: RuntimeConfiguration

  // MARK: Private

  private let state: StateStorage = .init()
  private let scopes: ScopeStorage = .init()
  private let dependencies: DependencyValues
  private let didStabilizeSubject = PublishSubject<Void, Never>()
  private let updateSubject = PublishSubject<[TreeEvent], Never>()
  private var transactionCount: Int = 0
  private var updates: TreeChanges = .none
  private var changeManager: StateUpdater?
  private var stateApplier: StateApplier?
  private var nodeCache: [NodeID: any Node] = [:]
  private var updateStats = UpdateStats()
}

// MARK: Lifecycle
extension Runtime {

  func flushUpdateStats() -> UpdateStats {
    let copy = updateStats
    updateStats = .init()
    return copy
  }

  func start<N: Node>(
    rootNode: N,
    initialState: TreeStateRecord? = nil
  ) throws -> NodeScope<N> {
    guard
      transactionCount == 0,
      updates == .none
    else {
      throw InTransactionError()
    }
    let capture = NodeCapture(rootNode)
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: self
    )
    let initialized = try uninitialized
      .initializeRoot(
        asType: N.self,
        dependencies: dependencies
      )
    let scope = try initialized.connect()
    emitUpdates(events: [.tree(event: .started(treeID: treeID))])
    if let initialState {
      try apply(state: initialState)
    } else {
      updateRouteRecord(
        at: .system,
        to: .single(scope.nid)
      )
    }
    return scope
  }

  func stop() {
    transaction {
      if let root {
        register(
          changes: .init(
            removedScopes: [root.nid]
          )
        )
      }
    }
    emitUpdates(events: [.tree(event: .stopped(treeID: treeID))])
  }
}

// MARK: Computed properties
extension Runtime {

  // MARK: Public

  public nonisolated var behaviorEvents: some Emitter<BehaviorEvent, Never> {
    configuration.behaviorTracker.behaviorEvents
  }

  // MARK: Internal

  var didStabilizeEmitter: some Emitter<Void, Never> {
    didStabilizeSubject
  }

  var root: AnyScope? {
    let rootScope = state
      .rootNodeID
      .flatMap { id in
        scopes.getScope(for: id)
      }
    return rootScope
  }

  var nodeIDs: [NodeID] {
    state.nodeIDs
  }

  var stateEmpty: Bool {
    state.nodeIDs.isEmpty
      && state.rootNodeID == nil
  }

  var runtimeEmpty: Bool {
    scopes.isEmpty
  }

  var isEmpty: Bool {
    stateEmpty && runtimeEmpty
  }

  var isActive: Bool {
    root?.isActive == true
  }

  var isPerformingStateChange: Bool {
    transactionCount != 0
      || changeManager != nil
  }

  nonisolated var behaviorTracker: BehaviorTracker {
    configuration.behaviorTracker
  }

  var activeIntent: ActiveIntent<NodeID>? {
    state.activeIntent
  }

  func checkConsistency() -> Bool {
    #if DEBUG
    let stateIDs = state.nodeIDs.sorted()
    let scopeKeys = scopes.scopeIDs.sorted()
    let hasRootUnlessEmpty = (
      state.rootNodeID != nil
        || state.nodeIDs.isEmpty
    )
    let isConsistent = (
      (stateIDs == scopeKeys)
        && hasRootUnlessEmpty
    )
    if !(isConsistent || isPerformingStateChange) {
      print(InternalStateInconsistency(
        state: state.snapshot(),
        scopes: scopes.scopes
      ).description)
    }
    assert(
      isConsistent || isPerformingStateChange
    )
    return isConsistent || isPerformingStateChange
    #else
    return true
    #endif
  }

  func recordIntentScopeDependency(_ scopeID: NodeID) {
    state.recordIntentNodeDependency(scopeID)
  }

  func popIntentStep() {
    state.popIntentStep()
  }

  func register(intent: Intent) throws {
    try state.register(intent: intent)
  }
}

// MARK: Public
extension Runtime {

  public nonisolated var info: StateTreeInfo {
    StateTreeInfo(
      runtime: self,
      scopes: scopes
    )
  }

  @_spi(Implementation)
  public func getScope(at routeID: RouteSource) throws -> AnyScope {
    guard
      let nodeID = try state
        .getRoutedNodeID(at: routeID)
    else {
      throw NodeNotFoundError(id: routeID.nodeID)
    }
    return try getScope(for: nodeID)
  }

  @_spi(Implementation)
  public func getScopes(at fieldID: FieldID) throws -> [AnyScope] {
    let nodeIDs = try state.getRouteRecord(at: fieldID)?.ids ?? []
    return scopes.getScopes(for: nodeIDs)
  }

  @_spi(Implementation)
  public func getScope(for nodeID: NodeID) throws -> AnyScope {
    if
      let scope = scopes
        .getScope(for: nodeID)
    {
      return scope
    } else {
      throw NodeNotFoundError(id: nodeID)
    }
  }
}

// MARK: Internal
extension Runtime {

  // MARK: Public

  public func snapshot() -> TreeStateRecord {
    state.snapshot()
  }

  // MARK: Internal

  func signal(intent: Intent) throws {
    guard let rootID = state.rootNodeID
    else {
      runtimeWarning("the intent could not be signalled as the tree is inactive.")
      return
    }
    try transaction {
      try state.register(intent: intent)
      updates.put(.init(dirtyScopes: [rootID]))
    }
  }

  func contains(_ scopeID: NodeID) -> Bool {
    assert(checkConsistency())
    return scopes.contains(scopeID)
  }

  func transaction<T>(_ action: () throws -> T) rethrows -> T {
    assert(transactionCount >= 0)
    transactionCount += 1
    let value = try action()
    guard transactionCount == 1
    else {
      transactionCount -= 1
      return value
    }
    defer {
      transactionCount -= 1
    }
    do {
      let nodeUpdates = try syncScopesToChanges(updates.take())
      emitUpdates(events: nodeUpdates)
    } catch {
      runtimeWarning(
        "An update failed leaving the tree in an illegal state."
      )
      assertionFailure("\(error.self)")
    }
    assert(checkConsistency())
    return value
  }

  func connect(scope: AnyScope) {
    assert(!scope.isActive)
    state.addRecord(scope.record)
    scopes.insert(scope)
  }

  func disconnect(scopeID: NodeID) {
    nodeCache.removeValue(forKey: scopeID)
    scopes.remove(id: scopeID)
    state.removeRecord(scopeID)
  }

  func updateRouteRecord(
    at fieldID: FieldID,
    to ids: RouteRecord
  ) {
    transaction {
      do {
        let stateChanges = try state
          .setRoutedNodeSet(at: fieldID, to: ids)
        register(
          changes: stateChanges + .init(routedScopes: ids.ids)
        )
      } catch {
        assertionFailure(error.localizedDescription)
      }
    }
  }

  func getRouteRecord(at fieldID: FieldID) -> RouteRecord? {
    do {
      return try state.getRouteRecord(at: fieldID)
    } catch {
      assertionFailure(error.localizedDescription)
      return nil
    }
  }

  @TreeActor
  func getRecord(_ nodeID: NodeID) -> NodeRecord? {
    state.getRecord(nodeID)
  }

  func getRoutedRecord(at routeID: RouteSource) -> NodeRecord? {
    if
      let nodeID = try? state.getRoutedNodeID(at: routeID),
      let record = state.getRecord(nodeID)
    {
      return record
    }
    return nil
  }

  func childScopes(of nodeID: NodeID) -> [AnyScope] {
    state
      .children(of: nodeID)
      .compactMap {
        do {
          return try getScope(for: $0)
        } catch {
          assertionFailure("state and scopes are inconsistent")
          return nil
        }
      }
  }

  func getValue<T: Codable & Hashable>(field: FieldID, as type: T.Type) -> T? {
    state.getValue(field, as: type)
  }

  func setValue(field: FieldID, to newValue: some Codable & Hashable) {
    transaction {
      if
        state.setValue(
          field,
          to: newValue
        ) == true
      {
        register(
          changes: .init(
            updatedValues: [field]
          )
        )
      }
    }
  }

  func ancestors(of nodeID: NodeID) -> [NodeID]? {
    state.ancestors(of: nodeID)
  }

  func apply(
    state newState: TreeStateRecord
  ) throws {
    guard
      transactionCount == 0,
      updates == .none
    else {
      throw InTransactionError()
    }
    transactionCount += 1
    defer {
      assert(updates == .none)
      assert(checkConsistency())
      transactionCount -= 1
    }
    let changes = try rebuildScopesForNewState(newState)
    emitUpdates(events: changes)
  }

  // MARK: Private

  private func emitUpdates(events: [TreeEvent]) {
    assert(
      events
        .compactMap(\.maybeNode)
        .map(\.depthOrder)
        .reduce((isSorted: true, lastDepth: Int.min)) { partialResult, depth in
          return (partialResult.isSorted && depth >= partialResult.lastDepth, depth)
        }
        .isSorted,
      "node events in an update batch should be sorted by ascending depth"
    )

    // Emit node events through nodes.
    //
    // This allows ui layer consumers to subscribe to only
    // the node they're representing, without having to filter -
    // and so avoids an n^2 growth in work required to tell the
    // ui layer about a node update.

    for event in events {
      if let nodeEvent = event.maybeNode {
        switch nodeEvent {
        case .start(let id, _):
          let scope = scopes.getScope(for: id)
          assert(scope?.isActive == true)
          scope?.sendUpdateEvent()
        case .update(let id, _):
          let scope = scopes.getScope(for: id)
          assert(scope?.isActive == true)
          scope?.sendUpdateEvent()
        case .stop(let id, _):
          /// The scope has been stopped but not disconnected.
          /// External consumers have not yet been notified.
          let scope = scopes.getScope(for: id)
          assert(scope != nil)
          scope?.disconnectSendingNotification()
        }
      }
    }

    // Finally, emit the update batch to the tree level information stream.
    updateSubject.emit(value: events)
  }

}

// MARK: Private implementation
extension Runtime {

  private func register(changes: TreeChanges) {
    if let changeManager {
      changeManager.flush(dependentChanges: changes)
    } else {
      updates.put(changes)
    }
  }

  private func syncScopesToChanges(
    _ treeChanges: TreeChanges
  ) throws
    -> [TreeEvent]
  {
    assert(stateApplier == nil)
    let updater = StateUpdater(
      changes: treeChanges,
      state: state,
      scopes: scopes
    )
    changeManager = updater
    defer { changeManager = nil }
    let updateInfo = try updater.flush()
    updateStats = updateStats.merged(with: updateInfo.stats)
    return updateInfo.events.map { .node(event: $0) }
  }

  private func rebuildScopesForNewState(
    _ newState: TreeStateRecord
  ) throws
    -> [TreeEvent]
  {
    let applier = StateApplier(
      newState: newState,
      stateStorage: state,
      scopeStorage: scopes
    )

    // Assert invariants.
    // - Regular changes should not be able to happen while a new state is applied to the runtime.
    // - Applying a state to the runtime should not itself change state.
    assert(
      changeManager == nil,
      "a state application should not be able to happen during a change"
    )
    let preApplicationUpdates = updates.take()
    assert(
      preApplicationUpdates.isEmpty,
      "a state application should not be able to happen when there are staged updates"
    )
    defer {
      let postApplicationUpdates = updates.take()
      assert(
        postApplicationUpdates.isEmpty,
        "state application should not lead to staged updates"
      )
    }

    stateApplier = applier
    defer {
      self.stateApplier = nil
    }

    let updateInfo = try applier.flush()
    updateStats = updateStats.merged(with: updateInfo.stats)
    return updateInfo.events.map { .node(event: $0) }
  }

}
