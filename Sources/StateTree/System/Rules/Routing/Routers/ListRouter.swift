import OrderedCollections
import TreeActor
@_spi(Implementation) import Utilities

// MARK: - ListRouter

public struct ListRouter<Element: Node>: RouterType {

  // MARK: Lifecycle

  init(
    buildKeys ids: some Collection<LSID>,
    builder: @escaping (LSID) throws -> Element
  ) {
    self.ids = OrderedSet(ids)
    self.elementBuilder = builder
  }

  // MARK: Public

  public typealias Value = [Element]

  public static var type: RouteType { .list }

  public let defaultRecord: RouteRecord = .list(.init(idMap: [:]))

  public var fallback: [Element] {
    []
  }

  @_spi(Implementation)
  public mutating func syncToState(
    field fieldID: FieldID,
    in runtime: Runtime
  ) throws -> [AnyScope] {
    guard let context
    else {
      throw UnassignedRouterError()
    }
    hasApplied = true
    let record = runtime.getRouteRecord(at: fieldID)
    guard case .list(let listRecord) = record
    else {
      assertionFailure()
      throw IncorrectRouterTypeError()
    }
    let missingScopeDetails: [(LSID, NodeID, NodeRecord)] = try listRecord.idMap.filter { pair in
      (try? runtime.getScope(for: pair.value)) == nil
    }.map { lsid, nid in
      guard let record = runtime.getRecord(nid)
      else {
        assertionFailure("missing expected record")
        throw NodeReinitializationError()
      }
      return (lsid, nid, record)
    }
    let newScopes = try missingScopeDetails.map { lsid, _, record in
      let node = try elementBuilder(lsid)
      let capture = NodeCapture(node)
      let scope = try recreateConnected(
        Element.self,
        from: capture,
        record: record,
        context: context,
        in: runtime
      )
      return scope.erase()
    }
    return newScopes
  }

  @_spi(Implementation)
  @TreeActor
  public func current(at fieldID: FieldID, in runtime: Runtime) throws -> Value {
    guard
      let scopes = try? runtime
        .getScopes(at: fieldID)
    else {
      throw UnassignedRouterError()
    }
    return scopes.compactMap { $0.node as? Element }
  }

  public mutating func assign(_ context: RouterRuleContext) {
    self.context = context
  }

  @_spi(Implementation)
  public mutating func apply(at fieldID: FieldID, in runtime: Runtime) throws {
    guard !hasApplied
    else {
      return
    }
    hasApplied = true

    guard let context
    else {
      throw UnassignedRouterError()
    }

    let record = runtime.getRouteRecord(at: fieldID)
    guard case .list(let listRecord) = record
    else {
      assertionFailure()
      throw IncorrectRouterTypeError()
    }
    let idMap = listRecord.idMap
    var newIDMap = OrderedDictionary<LSID, NodeID>()

    let newIDs = ids.subtracting(idMap.keys)
    let removedIDs = idMap.keys.subtracting(ids)

    for lsid in ids {
      if newIDs.contains(lsid) {
        let node = try elementBuilder(lsid)
        let capture = NodeCapture(node)
        let scope = try createConnected(
          Element.self,
          lsid: lsid,
          from: capture,
          context: context,
          at: fieldID,
          in: runtime
        )
        newIDMap[lsid] = scope.nid
      } else if let nid = idMap[lsid], !removedIDs.contains(lsid) {
        newIDMap[lsid] = nid
      }
    }

    runtime.updateRouteRecord(
      at: fieldID,
      to: .list(.init(idMap: newIDMap))
    )
  }

  public mutating func update(from other: ListRouter<Element>) {
    if other.ids != ids {
      self = other
    }
  }

  // MARK: Private

  private let elementBuilder: (LSID) throws -> Element
  private let ids: OrderedSet<LSID>
  private var hasApplied = false
  private var context: RouterRuleContext?

  @TreeActor
  private func recreateConnected<T: Node>(
    _: T.Type,
    from capture: NodeCapture,
    record: NodeRecord,
    context: RouterRuleContext,
    in runtime: Runtime
  ) throws -> NodeScope<T> {
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: runtime
    )
    let initialized = try uninitialized.reinitializeNode(
      asType: T.self,
      from: record,
      dependencies: context.dependencies,
      on: record.origin
    )
    return try initialized.connect()
  }

  @TreeActor
  private func createConnected<T: Node>(
    _: T.Type,
    lsid: LSID,
    from capture: NodeCapture,
    context: RouterRuleContext,
    at fieldID: FieldID,
    in runtime: Runtime
  ) throws -> NodeScope<T> {
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: runtime
    )
    let initialized = try uninitialized.initializeNode(
      asType: T.self,
      id: NodeID(),
      dependencies: context.dependencies,
      on: .init(
        fieldID: fieldID,
        identity: lsid,
        type: .list,
        depth: context.depth
      )
    )
    return try initialized.connect()
  }

}

// MARK: - MissingNodeKeyError

struct MissingNodeKeyError: Error { }

// MARK: - Route
extension Route {

  public init<NodeType: Node>(wrappedValue: [NodeType], line: Int = #line, col: Int = #column)
    where Router == ListRouter<NodeType>
  {
    let nodes = wrappedValue.enumerated()
      .reduce(into: OrderedDictionary<LSID, NodeType>()) { partialResult, pair in
        partialResult[LSID(prefix: "static-\(line):\(col)", hashable: pair.offset)] = pair.element
      }
    self.init(
      defaultRouter: ListRouter(
        buildKeys: nodes.keys,
        builder: { try nodes[$0].orThrow(MissingNodeKeyError()) }
      )
    )
  }
}

extension Serve {

  public init<NodeType: Node>(
    nodes: [NodeType],
    at route: Route<Router>,
    line: Int = #line,
    col: Int = #column
  )
    where Router == ListRouter<NodeType>
  {
    let nodes = nodes.enumerated()
      .reduce(into: OrderedDictionary<LSID, NodeType>()) { partialResult, pair in
        partialResult[LSID(prefix: "static-\(line):\(col)", hashable: pair.offset)] = pair.element
      }
    self.init(
      router: ListRouter(
        buildKeys: nodes.keys,
        builder: { try nodes[$0].orThrow(MissingNodeKeyError()) }
      ),
      at: route
    )
  }

  public init<Data: Collection, NodeType: Node>(
    data: Data,
    at route: Route<Router>,
    builder: @escaping (_ datum: Data.Element) -> NodeType
  ) where Data.Element: Identifiable,
    Router == ListRouter<NodeType>
  {
    let mapping = data
      .reduce(into: OrderedDictionary<LSID, Data.Element>()) { partialResult, value in
        partialResult[LSID(hashable: value.id)] = value
      }
    self.init(router: .init(buildKeys: mapping.keys, builder: { (lsid: LSID) in
      let datum = try mapping[lsid].orThrow(MissingNodeKeyError())
      return builder(datum)
    }), at: route)
  }

  public init<Data: Collection, NodeType: Node>(
    data: Data,
    at route: Route<Router>,
    builder: @escaping (_ datum: Data.Element) -> NodeType
  ) where Data.Element: Hashable,
    Router == ListRouter<NodeType>
  {
    let mapping = data
      .reduce(into: OrderedDictionary<LSID, Data.Element>()) { partialResult, value in
        partialResult[LSID(hashable: value)] = value
      }
    self.init(router: .init(buildKeys: mapping.keys, builder: { (lsid: LSID) in
      let datum = try mapping[lsid].orThrow(MissingNodeKeyError())
      return builder(datum)
    }), at: route)
  }
}

extension Serve {
  public init<Data: Collection>(
    data: Data,
    identifiedBy idPath: KeyPath<Data.Element, some Hashable>,
    at route: Route<Router>
  ) where Data.Element: Hashable,
    Router == ListRouter<Data.Element>
  {
    let mapping = data
      .reduce(into: OrderedDictionary<LSID, Data.Element>()) { partialResult, value in
        partialResult[LSID(hashable: value[keyPath: idPath])] = value
      }
    self.init(router: .init(buildKeys: mapping.keys, builder: { (lsid: LSID) in
      try mapping[lsid].orThrow(MissingNodeKeyError())
    }), at: route)
  }
}
