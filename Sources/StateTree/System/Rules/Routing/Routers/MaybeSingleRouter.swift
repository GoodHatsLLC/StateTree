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
    guard case .maybeSingle(let maybeSingleRecord) = record
    else {
      assertionFailure()
      throw IncorrectRouterTypeError()
    }
    guard let requiredID = maybeSingleRecord
    else {
      assert(capturedNode == nil)
      return []
    }
    guard
      let node = capturedNode,
      let record = runtime.getRecord(requiredID)
    else {
      throw InvalidSyncFailure()
    }
    if (try? runtime.getScope(for: requiredID)) != nil {
      return []
    }
    let capture = NodeCapture(node)
    let uninitialized = UninitializedNode(capture: capture, runtime: runtime)
    let initialized = try uninitialized.reinitializeNode(
      asType: NodeType.self,
      from: record,
      dependencies: context.dependencies,
      on: .init(fieldID: fieldID, identity: nil, type: .maybeSingle, depth: context.depth)
    )
    return [try initialized.connect().erase()]
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
    case (.some(let lhs), .some(let rhs)):
      if
        let lhsID = lhs.identity,
        let rhsID = rhs.identity,
        lhsID != rhsID
      {
        self = other
      }
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

extension Serve {
  public init<Value>(_ node: Value?, at route: Route<Router>) where Value: Node,
    Router == MaybeSingleRouter<Value>
  {
    self.init(router: Router(node: node), at: route)
  }
}
