import Behaviors
import Emitter
import Foundation
import HeapModule
import Utilities

// MARK: - Runtime

@TreeActor
@_spi(Implementation)
public final class Runtime {

  // MARK: Lifecycle

  nonisolated init(
    tree: Tree,
    dependencies: DependencyValues,
    configuration: RuntimeConfiguration
  ) {
    self.tree = tree
    self.dependencies = dependencies
    self.configuration = configuration
  }

  // MARK: Public

  public var updateEmitter: some Emitter<NodeChange> {
    updateSubject
  }

  // MARK: Internal

  let tree: Tree
  let configuration: RuntimeConfiguration

  // MARK: Private

  private let state: StateStorage = .init()
  private let scopes: ScopeStorage = .init()
  private let dependencies: DependencyValues
  private let didStabilizeSubject = PublishSubject<Void>()
  private let updateSubject = PublishSubject<NodeChange>()
  private var transactionCount: Int = 0
  private var updates: TreeChanges = .none
  private var changeManager: (any ChangeManager)?
  private var nodeCache: [NodeID: any Node] = [:]
}

// MARK: Lifecycle
extension Runtime {
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
      .initialize(
        as: N.self,
        depth: 0,
        dependencies: dependencies,
        on: .system
      )
    let scope = try initialized.connect()
    if let initialState {
      let change = try apply(state: initialState)
      emitUpdates(changes: change)
    } else {
      updateRoutedNodes(
        at: .system,
        to: .single(.init(id: scope.nid))
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
  }
}

// MARK: Computed properties
extension Runtime {

  var didStabilizeEmitter: some Emitter<Void> {
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

  var isConsistent: Bool {
    let stateIDs = state.nodeIDs
    let scopeKeys = scopes.scopeIDs
    let hasRootUnlessEmpty = (
      state.rootNodeID != nil
        || state.nodeIDs.isEmpty
    )
    let isConsistent = (
      (stateIDs == scopeKeys)
        && hasRootUnlessEmpty
    )
    assert(
      isConsistent || isPerformingStateChange,
      InternalStateInconsistency(
        state: state.snapshot(),
        scopes: scopes.scopes
      ).description
    )
    return isConsistent
  }

  var isActive: Bool {
    root?.isActive == true
  }

  var isPerformingStateChange: Bool {
    transactionCount != 0
      || changeManager != nil
  }

  var behaviorManager: BehaviorManager {
    configuration.behaviorManager
  }

  var activeIntent: ActiveIntent? {
    state.activeIntent
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

  // MARK: Public

  public var _info: StateTreeInfo {
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
      throw NodeNotFoundError()
    }
    return try getScope(for: nodeID)
  }

  @_spi(Implementation)
  public func getScope(for nodeID: NodeID) throws -> AnyScope {
    if
      let scope = scopes
        .getScope(for: nodeID)
    {
      return scope
    } else {
      throw NodeNotFoundError()
    }
  }

  // MARK: Internal

  func getNode(id: NodeID) -> (any Node)? {
    nodeCache[id] ?? {
      let node = try? getScope(for: id).node
      nodeCache[id] = node
      return node
    }()
  }

}

// MARK: Internal
extension Runtime {

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
    assert(isConsistent)
    return scopes.contains(scopeID)
  }

  func snapshot() -> TreeStateRecord {
    state.snapshot()
  }

  func transaction<T>(_ action: () throws -> T) rethrows -> T {
    let validState = state.snapshot()
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
      let changes = try updateScopes(
        lastValidState: validState
      )
      emitUpdates(changes: changes)
    } catch {
      runtimeWarning(
        "An update failed and couldn't be reverted leaving the tree in an illegal state."
      )
      assertionFailure(
        error.localizedDescription
      )
    }
    assert(isConsistent)
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

  func updateRoutedNodes(
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

  func getRoutedNodeSet(at fieldID: FieldID) -> RouteRecord? {
    do {
      return try state.getRoutedNodeSet(at: fieldID)
    } catch {
      assertionFailure(error.localizedDescription)
      return nil
    }
  }

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

  func getValue<T: TreeState>(field: FieldID, as type: T.Type) -> T? {
    state.getValue(field, as: type)
  }

  func setValue(field: FieldID, to newValue: some TreeState) {
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

  func set(state newState: TreeStateRecord) throws {
    let changes = try apply(state: newState)
    emitUpdates(changes: changes)
  }

  // MARK: Private

  private func emitUpdates(changes: [NodeChange]) {
    for change in changes {
      updateSubject.emit(
        .value(change)
      )
    }
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

  private func updateScopes(
    lastValidState: TreeStateRecord
  ) throws
    -> [NodeChange]
  {
    let updater = StateUpdater(
      changes: updates.take(),
      state: state,
      scopes: scopes,
      lastValidState: lastValidState,
      userError: configuration.userError
    )
    changeManager = updater
    defer { changeManager = nil }
    return try updater.flush()
  }

  private func apply(
    state newState: TreeStateRecord
  ) throws
    -> [NodeChange]
  {
    guard
      transactionCount == 0,
      updates == .none
    else {
      throw InTransactionError()
    }
    transactionCount += 1
    let applier = StateApplier(
      state: state,
      scopes: scopes
    )
    changeManager = applier
    defer {
      assert(updates == .none)
      assert(isConsistent)
      transactionCount -= 1
      changeManager = nil
    }
    return try applier.apply(
      state: newState
    )
  }

}
