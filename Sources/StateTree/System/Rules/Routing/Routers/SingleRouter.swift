import TreeActor

// MARK: - SingleRouter

public struct SingleRouter<NodeType: Node>: RouterType {

  // MARK: Lifecycle

  init(builder: () -> NodeType) {
    self.capturedNode = builder()
  }

  // MARK: Public

  public typealias Value = NodeType

  public static var type: RouteType { .single }

  public let defaultRecord: RouteRecord = .single(.invalid)

  public var fallback: NodeType {
    capturedNode
  }

  public var current: NodeType {
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
        type: .single,
        depth: writeContext.depth
      )
    )
    let node = try initialized.connect()
    connection.runtime.updateRouteRecord(
      at: connection.fieldID,
      to: .single(node.nid)
    )
  }

  public mutating func update(from _: SingleRouter<NodeType>) {
    // Update is called when the route call has structural equality.
  }

  // MARK: Private

  private let capturedNode: NodeType
  private var hasApplied = false
  private var connection: RouteConnection?
  private var writeContext: RouterWriteContext?

}

// MARK: - Route
extension Route {

  public init<NodeType: Node>(wrappedValue: @autoclosure () -> NodeType)
    where Router == SingleRouter<NodeType>
  {
    self.init(defaultRouter: SingleRouter(builder: wrappedValue))
  }
}

extension Attach {
  public init<Value>(_ route: Route<Router>, to node: Value) where Value: Node,
    Router == SingleRouter<Value>
  {
    self.init(router: Router(builder: { node }), to: route)
  }
}
