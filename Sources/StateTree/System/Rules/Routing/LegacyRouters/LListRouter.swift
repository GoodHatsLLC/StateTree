// import Disposable
// import OrderedCollections
// import TreeActor
// @_spi(Implementation) import Utilities
//
//// MARK: - ListRouter
//
// public struct ListRouter<NodeType: Node>: NRouterType {
//  public static var type: RouteType { .list }
//
//  public init(ids: OrderedSet<LSID>, builder: @escaping (LSID) -> NodeType, fieldID: FieldID) {
//    self.builder = builder
//    self.fieldID = fieldID
//    self.ids = ids
//  }
//
//  public typealias Value = [NodeType]
//  private var ids: OrderedSet<LSID>
//  public private(set) var builder: (LSID) -> NodeType
//  private let fieldID: FieldID
// }
//
//// MARK: RouterType
//
// extension ListRouter {
//
//  // MARK: Public
//
//  @TreeActor
//  @_spi(Implementation)
//  public static func getValue(
//    for record: RouteRecord,
//    in runtime: Runtime
//  ) throws -> [NodeType] {
//    guard case .list(let list) = record
//    else {
//      throw InvalidRouteRecordError()
//    }
//    return list.nodeIDs
//      .compactMap { id in
//        let node = try? runtime.getScope(for: id).node as? NodeType
//        return node
//      }
//  }
//
//  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
//    switch lifecycle {
//    case .didStart:
//      break
//    case .didUpdate:
//      break
//    case .willStop:
//      break
//    case .handleIntent:
//      break
//    }
//    return .init()
//  }
//
//  @TreeActor
//  public mutating func applyRule(with context: RuleContext) throws {
//    try updateScopes(context: context)
//  }
//
//  @TreeActor
//  public mutating func updateRule(
//    from new: ListRouter<NodeType>,
//    with context: RuleContext
//  ) throws {
//    ids = new.ids
//    builder = new.builder
//    try updateScopes(context: context)
//  }
//
//  @TreeActor
//  public mutating func removeRule(with context: RuleContext) throws {
//    ids = []
//    context.runtime
//      .updateRouteRecord(at: fieldID, to: .list(.init(idMap: [:])))
//  }
//
//  // MARK: Private
//
//  private func updateScopes(context: RuleContext) throws {
//    let existingScopes = try context.runtime.getScopes(at: fieldID)
//    let existingScopeNodeIDs = Set(existingScopes.map(\.nid))
//    let expCurr = context.runtime.getRouteRecord(at: fieldID)
//    assert(expCurr != nil)
//    let current = expCurr ?? .list(.init(idMap: [:]))
//    guard case .list(var list) = current
//    else {
//      throw UnexpectedMemberTypeError()
//    }
//
////    let existingIDs = list.idMap.keys
//
//    // FIXME: we shouldn't really just arbitrarily accept that some scopes might not exist.
//    let existingIDs = list.idMap.filter { el in
//      existingScopeNodeIDs.contains(el.value)
//    }.keys
//
//    let newIDs = ids
//    let remove = existingIDs.subtracting(newIDs)
//    let add = newIDs.subtracting(existingIDs)
//
//    for id in remove {
//      list.idMap.removeValue(forKey: id)
//    }
//
//    let idPairs = try add.map { id -> (lsid: LSID, nid: NodeID) in
//      let node = builder(id)
//      let capture = NodeCapture(node)
//      let scope = try UninitializedNode(
//        capture: capture,
//        runtime: context.runtime
//      )
//      .initialize(
//        as: NodeType.self,
//        depth: context.depth + 1,
//        dependencies: context.dependencies,
//        on: .init(
//          fieldID: fieldID,
//          identity: id,
//          type: .list
//        )
//      )
//      .connect()
//      let nodeID = scope.nid
//
//      return (lsid: id, nid: nodeID)
//    }
//
//    for pair in idPairs {
//      list.idMap[pair.lsid] = pair.nid
//    }
//
//    context.runtime.updateRouteRecord(at: fieldID, to: .list(list))
//  }
//
// }
