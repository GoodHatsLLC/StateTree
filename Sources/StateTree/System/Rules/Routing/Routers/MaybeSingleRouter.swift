import TreeActor

// MARK: - MaybeSingleRouter

public struct MaybeSingleRouter<NodeType: Node>: RouterType {

  // MARK: Lifecycle

  init(builder: () -> NodeType?) {
    self.capturedNode = builder()
  }

  // MARK: Public

  public typealias Value = NodeType?

  public static var type: RouteType { .maybeSingle }

  public let defaultRecord: RouteRecord = .maybeSingle(nil)

  public var fallback: NodeType? {
    capturedNode
  }

  public var current: NodeType? {
    guard
      let connection = connection,
      let scope = try? connection.runtime
        .getScopes(at: connection.fieldID).first,
      let node = scope.node as? NodeType
    else {
      return capturedNode
    }
    return node
  }

  public mutating func apply(connection: RouteConnection, writeContext: RouterWriteContext) throws {
    guard !hasApplied
    else {
      return
    }
    hasApplied = true

    self.connection = connection
    self.writeContext = writeContext

    guard let capturedNode
    else {
      connection.runtime.updateRouteRecord(
        at: connection.fieldID,
        to: .maybeSingle(nil)
      )
      return
    }
    let capture = NodeCapture(capturedNode)
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: connection.runtime
    )
    let initialized = try uninitialized.initializeNode(
      asType: NodeType.self,
      id: NodeID(),
      dependencies: writeContext.dependencies,
      on: .init(
        fieldID: connection.fieldID,
        identity: nil,
        type: .maybeSingle,
        depth: writeContext.depth
      )
    )
    let node = try initialized.connect()
    connection.runtime.updateRouteRecord(
      at: connection.fieldID,
      to: .maybeSingle(node.nid)
    )
  }

  public mutating func update(from other: MaybeSingleRouter<NodeType>) {
    switch (capturedNode, other.capturedNode) {
    case
      (.none, .some),
      (.some, .none):
      var other = other
      other.connection = connection
      other.writeContext = writeContext
      other.hasApplied = false
      self = other
    default:
      break
    }
  }

  // MARK: Private

  private let capturedNode: NodeType?
  private var hasApplied = false
  private var connection: RouteConnection?
  private var writeContext: RouterWriteContext?

}

extension Route {

  // MARK: Lifecycle

  public init<NodeType>(wrappedValue: @autoclosure () -> NodeType? = nil)
    where Router == MaybeSingleRouter<NodeType>
  {
    self.init(defaultRouter: MaybeSingleRouter(builder: wrappedValue))
  }

  // MARK: Public

  @TreeActor
  public func route<Value>(builder: () -> Value?) -> Attach<Router>
    where Router == MaybeSingleRouter<Value>
  {
    Attach<Router>(router: MaybeSingleRouter(builder: builder), to: self)
  }
}

extension Attach {
  public init<Value>(_ route: Route<Router>, to node: Value?) where Value: Node,
    Router == MaybeSingleRouter<Value>
  {
    self.init(router: Router(builder: { node }), to: route)
  }
}
