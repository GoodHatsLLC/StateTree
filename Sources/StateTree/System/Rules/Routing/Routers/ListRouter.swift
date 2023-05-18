import Disposable
import OrderedCollections
import TreeActor
@_spi(Implementation) import Utilities

// MARK: - ListRouter

public struct ListRouter<NodeType: Node>: NRouterType {
  public static var routeType: RouteType { .list }

  public init(ids: OrderedSet<LSID>, builder: @escaping (LSID) -> NodeType?, fieldID: FieldID) {
    self.builder = builder
    self.fieldID = fieldID
    self.ids = ids
  }

  public typealias Value = [NodeType]
  private var ids: OrderedSet<LSID>
  public private(set) var builder: (LSID) -> NodeType?
  private let fieldID: FieldID
}

// MARK: RouterType

extension ListRouter {
  @TreeActor
  @_spi(Implementation)
  public static func value(
    for record: RouteRecord,
    in runtime: Runtime
  ) -> [NodeType]? {
    guard case .list(let list) = record
    else {
      return nil
    }
    return list.nodeIDs
      .compactMap { id in
        let node = try? runtime.getScope(for: id).node as? NodeType
        return node
      }
  }

  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    switch lifecycle {
    case .didStart:
      break
    case .didUpdate:
      break
    case .willStop:
      break
    case .handleIntent:
      break
    }
    return .init()
  }

  @TreeActor
  public mutating func applyRule(with context: RuleContext) throws {
    try updateBackingRecord(context: context)
  }

  @TreeActor
  public mutating func updateRule(
    from new: ListRouter<NodeType>,
    with context: RuleContext
  ) throws {
    if ids != new.ids {
      builder = new.builder
      ids = new.ids
      try updateBackingRecord(context: context)
    }
  }

  @TreeActor
  public mutating func removeRule(with context: RuleContext) throws {
    ids = []
    context.runtime
      .updateRouteRecord(at: fieldID, to: .list(.init(idMap: [:])))
  }

  public func updateBackingRecord(context: RuleContext) throws {
    let expCurr = context.runtime.getRouteRecord(at: fieldID)
    assert(expCurr != nil)
    let current = expCurr ?? .list(.init(idMap: [:]))
    guard case .list(var list) = current
    else {
      throw UnexpectedMemberTypeError()
    }

    // FIXME: when recreating state, the state says nodes exist,
    // but the scopes don't actually exist — and so they don't get
    // made here. (why does this work elsewhere? should it?)

    let existingIDs = list.idMap.keys
    let newIDs = ids
    let remove = existingIDs.subtracting(newIDs)
    let add = newIDs.subtracting(existingIDs)

    for id in remove {
      list.idMap.removeValue(forKey: id)
    }

    let idPairs = try add.compactMap { id -> (lsid: LSID, nid: NodeID)? in
      guard let node = builder(id)
      else {
        return nil
      }
      let capture = NodeCapture(node)
      let scope = try UninitializedNode(
        capture: capture,
        runtime: context.runtime
      )
      .initialize(
        as: NodeType.self,
        depth: context.depth + 1,
        dependencies: context.dependencies,
        on: .init(
          fieldID: fieldID,
          identity: id,
          type: .list
        )
      )
      .connect()
      let nodeID = scope.nid

      return (lsid: id, nid: nodeID)
    }

    for pair in idPairs {
      list.idMap[pair.lsid] = pair.nid
    }

    context.runtime.updateRouteRecord(at: fieldID, to: .list(list))
  }

}
