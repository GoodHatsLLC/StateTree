import Intents
import TreeState

// MARK: properties
extension TreeStateRecord {

  var isValidInitialState: Bool {
    guard
      let root,
      nodes[root] != nil
    else {
      return false
    }
    return true
  }

}

// MARK: Focus
extension TreeStateRecord {

  func parent(of nodeID: NodeID) -> NodeID? {
    guard let record = getRecord(nodeID)
    else {
      return nil
    }
    return record.origin.nodeID
  }

  func ancestors(of nodeID: NodeID) -> [NodeID]? {
    guard let record = getRecord(nodeID)
    else {
      return nil
    }
    var ancestors = [NodeID]()
    var lastRecord = record
    while lastRecord.origin != .system {
      guard let record = getRecord(lastRecord.origin.nodeID)
      else {
        assertionFailure("disconnected node")
        return nil
      }
      ancestors.append(record.id)
      lastRecord = record
    }
    return ancestors.reversed()
  }

  func contains(nodeID: NodeID) -> Bool {
    nodes[nodeID] != nil
  }

  mutating func popIntentStep() {
    if var activeIntent {
      let (_, isValid) = activeIntent.popStep()
      if isValid {
        assert(activeIntent.isValid)
        self.activeIntent = activeIntent
      } else {
        assert(!activeIntent.isValid)
        self.activeIntent = nil
      }
    }
  }

  mutating func recordIntentNodeDependency(_ nodeID: NodeID) {
    activeIntent?.recordConsumer(nodeID)
  }

  mutating func register(intent: Intent) throws {
    if let root {
      activeIntent = .init(intent: intent, from: root)
    } else {
      throw RootNodeMissingError()
    }
  }

  mutating func invalidateIntentIfUsingNodeID(_ nodeID: NodeID) {
    if
      let activeIntent,
      activeIntent.consumerIDs.contains(nodeID)
    {
      self.activeIntent = nil
    }
  }

}

// MARK: Values
extension TreeStateRecord {

  func getValue<T: TreeState>(_ fieldID: FieldID, as _: T.Type) -> T? {
    if
      let node = nodes[fieldID.nodeID],
      node.records.count > fieldID.offset,
      case .value(let value) = node.records[fieldID.offset].payload
    {
      return value.anyValue as? T
    }
    return nil
  }

  mutating func setValue(_ fieldID: FieldID, to newValue: some TreeState) -> Bool? {
    if
      let node = nodes[fieldID.nodeID],
      node.records.count > fieldID.offset,
      case .value(var value) = node.records[fieldID.offset].payload
    {
      let newValue = AnyTreeState(newValue)
      if value != newValue {
        value = newValue
        nodes[fieldID.nodeID]?.records[fieldID.offset].payload = .value(value)
        return true
      } else {
        return false
      }
    } else {
      return nil
    }
  }

  func values(on nodeIDs: some Collection<NodeID>) -> [ValueRecord] {
    nodeIDs
      .compactMap { nodeID in
        nodes[nodeID]
      }
      .flatMap { record in
        record.records
          .compactMap { fieldRecord in
            fieldRecord.value()
              .map { .init(id: fieldRecord.id, value: $0) }
          }
      }
  }
}

// MARK: Records
extension TreeStateRecord {
  func valueRecords() -> [ValueRecord] {
    nodes.values
      .flatMap { record in
        record
          .records
          .compactMap { field in
            if case .value(let valueRecord) = field.payload {
              return .init(id: field.id, value: valueRecord)
            } else {
              return nil
            }
          }
      }
  }

  func getRecord(_ nodeID: NodeID) -> NodeRecord? {
    nodes[nodeID]
  }

  func getRecords(_ idSet: RouteRecord) -> [NodeRecord] {
    let records = idSet
      .ids
      .compactMap {
        nodes[$0]
      }
    assert(
      records.map(\.id) == idSet.ids,
      "not all node ids where backed by records"
    )
    return records
  }
}

// MARK: Routes
extension TreeStateRecord {

  /// Returns removed nodes
  mutating func swapRoutedNodeSet(
    at field: FieldID,
    to nodeIDs: RouteRecord
  ) throws
    -> RouteRecord?
  {
    guard
      let node = nodes[field.nodeID],
      node.records.count > field.offset,
      case .route(let original) = node.records[field.offset].payload
    else {
      throw NodeNotFoundError()
    }
    nodes[field.nodeID]?.records[field.offset].payload = .route(nodeIDs)
    return original
  }

  func getRoutedNodeSet(at route: FieldID) throws -> RouteRecord? {
    guard route.type == .route
    else {
      throw UnexpectedMemberTypeError()
    }
    guard
      let hostRecord = nodes[route.nodeID],
      hostRecord.records.count > route.offset
    else {
      return nil
    }
    switch hostRecord.records[route.offset].payload {
    case .route(let route):
      return route
    default:
      throw UnexpectedMemberTypeError()
    }
  }

  func getRoutedNodeID(at routeID: RouteSource) throws -> NodeID? {
    if
      let root = root,
      routeID.fieldID == .system
    {
      return root
    }

    guard
      let hostRecord = nodes[routeID.nodeID],
      hostRecord.records.count > routeID.fieldID.offset
    else {
      return nil
    }
    let field = hostRecord.records[routeID.fieldID.offset]
    switch field.payload {
    case .route(let route):
      return route.nodeID(matching: routeID)
    default:
      throw UnexpectedMemberTypeError()
    }
  }

  func children(of nodeID: NodeID) -> [NodeID] {
    let records = getRecord(nodeID)?.records ?? []
    return records
      .flatMap { field in
        switch field.payload {
        case .route(let route):
          return route.ids
        case _:
          return []
        }
      }
  }
}

// MARK: - StateJSONDecodingError

struct StateJSONDecodingError: Error { }
