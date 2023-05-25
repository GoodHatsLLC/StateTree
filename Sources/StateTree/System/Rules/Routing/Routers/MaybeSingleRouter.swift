import TreeActor

// MARK: - MaybeSingleRouter

public struct MaybeSingleRouter<NodeType: Node>: RouterType {

  // MARK: Lifecycle

  init(node: NodeType?) {
    self.capturedNode = node
  }

  // MARK: Public

  public typealias Value = NodeType?

  public static var type: RouteType { .maybeSingle }

  public let defaultRecord: RouteRecord = .maybeSingle(nil)

  public var fallback: NodeType? {
    capturedNode
  }

  @_spi(Implementation)
  @TreeActor
  public func current(at fieldID: FieldID, in runtime: Runtime) throws -> Value {
    guard
      let scope = try? runtime
        .getScopes(at: fieldID).first,
      let node = scope.node as? NodeType
    else {
      return capturedNode
    }
    return node
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

    guard let capturedNode
    else {
      runtime.updateRouteRecord(
        at: fieldID,
        to: .maybeSingle(nil)
      )
      return
    }
    let capture = NodeCapture(capturedNode)
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: runtime
    )
    let initialized = try uninitialized.initializeNode(
      asType: NodeType.self,
      id: NodeID(),
      dependencies: context.dependencies,
      on: .init(
        fieldID: fieldID,
        identity: nil,
        type: .maybeSingle,
        depth: context.depth
      )
    )
    let node = try initialized.connect()
    runtime.updateRouteRecord(
      at: fieldID,
      to: .maybeSingle(node.nid)
    )
  }

  public mutating func update(from other: MaybeSingleRouter<NodeType>) {
    switch (capturedNode, other.capturedNode) {
    case
      (.none, .some),
      (.some, .none):
      self = other
    default:
      break
    }
  }

  // MARK: Private

  private let capturedNode: NodeType?
  private var hasApplied = false
  private var context: RouterRuleContext?

}

extension Route {

  public init<NodeType>(wrappedValue: NodeType?)
    where Router == MaybeSingleRouter<NodeType>
  {
    self.init(defaultRouter: MaybeSingleRouter(node: wrappedValue))
  }
}

extension Attach {
  public init<Value>(_ route: Route<Router>, to node: Value?) where Value: Node,
    Router == MaybeSingleRouter<Value>
  {
    self.init(router: Router(node: node), to: route)
  }
}
