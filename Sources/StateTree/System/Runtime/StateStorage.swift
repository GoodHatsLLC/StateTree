import Intents
import TreeActor

// MARK: - StateStorage

@TreeActor
final class StateStorage {

  // MARK: Lifecycle

  nonisolated init() { }

  // MARK: Private

  private var state: TreeStateRecord = .init()
}

extension StateStorage {

  var rootNodeID: NodeID? {
    state.root
  }

  var nodeIDs: [NodeID] {
    state.nodeIDs
  }

  var activeIntent: ActiveIntent<NodeID>? {
    state.activeIntent
  }

  func register(intent: Intent) throws {
    try state.register(intent: intent)
  }

  func recordIntentNodeDependency(_ nodeID: NodeID) {
    state.recordIntentNodeDependency(nodeID)
  }

  func popIntentStep() {
    state.popIntentStep()
  }

  func snapshot() -> TreeStateRecord {
    state
  }

  func apply(state newState: TreeStateRecord) {
    state = newState
  }

  func getRecord(_ nodeID: NodeID) -> NodeRecord? {
    state.getRecord(nodeID)
  }

  func getRecords(_ idSet: RouteRecord) -> [NodeRecord] {
    state.getRecords(idSet)
  }

  func addRecord(_ node: NodeRecord) {
    state.nodes[node.id] = node
  }

  func removeRecord(_ nodeID: NodeID) {
    state.invalidateIntentIfUsingNodeID(nodeID)
    state.nodes
      .removeValue(forKey: nodeID)
  }

  func getValue<T: Codable & Hashable>(_ fieldID: FieldID, as type: T.Type) -> T? {
    state.getValue(fieldID, as: type)
  }

  func setValue(_ fieldID: FieldID, to newValue: some Codable & Hashable) -> Bool? {
    state.setValue(fieldID, to: newValue)
  }

  func values(on nodes: some Collection<NodeID>) -> [ValueRecord] {
    state.values(on: nodes)
  }

  /// Returns node change information
  func setRoutedNodeSet(at field: FieldID, to nodeIDs: RouteRecord) throws -> TreeChanges {
    if field == .system {
      let oldRoot = state.root
      if case .single(let single) = nodeIDs {
        state.root = single?.id
      } else {
        throw NodesNotFoundError(ids: nodeIDs.ids)
      }
      return .init(
        addedScopes: [state.root].compactMap { $0 },
        removedScopes: [oldRoot].compactMap { $0 }
      )
    }
    let swappedOut = try state.swapRoutedNodeSet(at: field, to: nodeIDs)
    let originals = Set(swappedOut?.ids ?? [])
    let new = Set(nodeIDs.ids)
    return TreeChanges(
      addedScopes: Array(new.subtracting(originals)),
      removedScopes: Array(originals.subtracting(new))
    )
  }

  func getRoutedNodeSet(at route: FieldID) throws -> RouteRecord? {
    if
      let root = state.root,
      route == .system
    {
      return .single(.init(id: root))
    }
    return try state.getRoutedNodeSet(at: route)
  }

  func getRoutedNodeID(at routeID: RouteSource) throws -> NodeID? {
    try state.getRoutedNodeID(at: routeID)
  }

  func children(of nodeID: NodeID) -> [NodeID] {
    state.children(of: nodeID)
  }

  func ancestors(of nodeID: NodeID) -> [NodeID]? {
    state.ancestors(of: nodeID)
  }

  func parent(of nodeID: NodeID) -> NodeID? {
    state.parent(of: nodeID)
  }

  func contains(nodeID: NodeID) -> Bool {
    state.contains(nodeID: nodeID)
  }

}
