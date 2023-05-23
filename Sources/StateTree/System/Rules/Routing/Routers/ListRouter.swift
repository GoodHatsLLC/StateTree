import OrderedCollections
import TreeActor
@_spi(Implementation) import Utilities

// MARK: - ListRouter

public struct ListRouter<Element: Node>: RouterType {

  // MARK: Lifecycle

  init<IDCollection: Collection>(
    buildKeys ids: IDCollection,
    builder: @escaping (LSID) throws -> Element
  ) where IDCollection.Element: Hashable {
    self.ids = OrderedSet(ids.map { LSID(hashable: $0) })
    self.elementBuilder = builder
  }

  // MARK: Public

  public typealias Value = [Element]

  public static var type: RouteType { .list }

  public let defaultRecord: RouteRecord = .list(.init(idMap: [:]))

  public var fallback: [Element] {
    []
  }

  public var current: [Element] {
    guard
      let connection = connection,
      let scopes = try? connection.runtime
        .getScopes(at: connection.fieldID)
    else {
      return fallback
    }
    return scopes.compactMap { $0.node as? Element }
  }

  public mutating func apply(connection: RouteConnection, writeContext: RouterWriteContext) throws {
    guard !hasApplied
    else {
      return
    }
    hasApplied = true

    let record = connection.runtime.getRouteRecord(at: connection.fieldID)
    guard case .list(let listRecord) = record
    else {
      assertionFailure()
      return
    }
    var idMap = listRecord.idMap

    let newIDs = ids.subtracting(idMap.keys)
    idMap.removeAll { pair in
      !ids.contains(pair.key)
    }

    for lsid in newIDs {
      let node = try elementBuilder(lsid)
      let capture = NodeCapture(node)
      let scope = try connect(
        Element.self,
        from: capture,
        connection: connection,
        writeContext: writeContext
      )
      idMap[lsid] = scope.nid
    }

    connection.runtime.updateRouteRecord(
      at: connection.fieldID,
      to: .list(.init(idMap: idMap))
    )
  }

  public mutating func update(from other: ListRouter<Element>) {
    if other.ids != ids {
      var other = other
      other.hasApplied = false
      other.connection = connection
      other.writeContext = writeContext
      self = other
    }
  }

  // MARK: Private

  private let elementBuilder: (LSID) throws -> Element
  private let ids: OrderedSet<LSID>
  private var hasApplied = false
  private var connection: RouteConnection?
  private var writeContext: RouterWriteContext?

  @TreeActor
  private func connect<T: Node>(
    _: T.Type,
    from capture: NodeCapture,
    connection: RouteConnection,
    writeContext: RouterWriteContext
  ) throws -> NodeScope<T> {
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: connection.runtime
    )
    let initialized = try uninitialized.initializeNode(
      asType: T.self,
      id: NodeID(),
      dependencies: writeContext.dependencies,
      on: .init(
        fieldID: connection.fieldID,
        identity: nil,
        type: .union2,
        depth: writeContext.depth
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
    let nodes = wrappedValue.enumerated().reduce(into: [LSID: NodeType]()) { partialResult, pair in
      partialResult[LSID(hashable: pair.offset)] = pair.element
    }
    self.init(
      defaultRouter: ListRouter(
        buildKeys: Array([0 ..< wrappedValue.count]),
        builder: { try nodes[$0].orThrow(MissingNodeKeyError()) }
      )
    )
  }
}

extension Attach {
  public init<Data: Collection>(
    _ route: Route<Router>,
    data: Data,
    builder _: @escaping (Data.Element) -> some Node
  ) where Data.Element: Hashable,
    Router == ListRouter<Data.Element>
  {
    let mapping = data.reduce(into: [LSID: Data.Element]()) { partialResult, value in
      partialResult[LSID(hashable: value)] = value
    }
    self.init(router: .init(buildKeys: data, builder: { (lsid: LSID) in
      try mapping[lsid].orThrow(MissingNodeKeyError())
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
    let mapping = data.reduce(into: [LSID: Data.Element]()) { partialResult, value in
      partialResult[LSID(hashable: value[keyPath: idPath])] = value
    }
    self.init(router: .init(buildKeys: data, builder: { (lsid: LSID) in
      try mapping[lsid].orThrow(MissingNodeKeyError())
    }), to: route)
  }
}
