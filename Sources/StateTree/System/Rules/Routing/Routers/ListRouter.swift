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
  public mutating func syncToState(field _: FieldID, in _: Runtime) throws -> [AnyScope] { [] }

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
      return
    }
    let idMap = listRecord.idMap
    var newIDMap = OrderedDictionary<LSID, NodeID>()

    let newIDs = ids.subtracting(idMap.keys)
    let removedIDs = idMap.keys.subtracting(ids)

    for lsid in ids {
      if newIDs.contains(lsid) {
        let node = try elementBuilder(lsid)
        let capture = NodeCapture(node)
        let scope = try connect(
          Element.self,
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
  private func connect<T: Node>(
    _: T.Type,
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
        identity: nil,
        type: .union2,
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

  public init<NodeType: Node>(wrappedValue: [NodeType])
    where Router == ListRouter<NodeType>
  {
    let nodes = wrappedValue.enumerated()
      .reduce(into: OrderedDictionary<LSID, NodeType>()) { partialResult, pair in
        partialResult[LSID(hashable: pair.offset)] = pair.element
      }
    self.init(
      defaultRouter: ListRouter(
        buildKeys: nodes.keys,
        builder: { try nodes[$0].orThrow(MissingNodeKeyError()) }
      )
    )
  }
}

extension Attach {

  public init<NodeType: Node>(_ route: Route<Router>, to nodes: [NodeType])
    where Router == ListRouter<NodeType>
  {
    let nodes = nodes.enumerated()
      .reduce(into: OrderedDictionary<LSID, NodeType>()) { partialResult, pair in
        partialResult[LSID(hashable: pair.offset)] = pair.element
      }
    self.init(
      router: ListRouter(
        buildKeys: nodes.keys,
        builder: { try nodes[$0].orThrow(MissingNodeKeyError()) }
      ),
      to: route
    )
  }

  public init<Data: Collection, NodeType: Node>(
    _ route: Route<Router>,
    data: Data,
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
    }), to: route)
  }
}

extension Attach {
  public init<Data: Collection>(
    _ route: Route<Router>,
    data: Data,
    identifiedBy idPath: KeyPath<Data.Element, some Hashable>,
    builder _: @escaping (Data.Element) -> some Node
  ) where Data.Element: Hashable,
    Router == ListRouter<Data.Element>
  {
    let mapping = data
      .reduce(into: OrderedDictionary<LSID, Data.Element>()) { partialResult, value in
        partialResult[LSID(hashable: value[keyPath: idPath])] = value
      }
    self.init(router: .init(buildKeys: mapping.keys, builder: { (lsid: LSID) in
      try mapping[lsid].orThrow(MissingNodeKeyError())
    }), to: route)
  }
}
