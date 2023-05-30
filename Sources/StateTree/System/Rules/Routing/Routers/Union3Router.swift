import TreeActor

// MARK: - Union3Router

public struct Union3Router<A: Node, B: Node, C: Node>: RouterType {

  // MARK: Lifecycle

  init(builder: () -> Union.Three<A, B, C>) {
    let capturedUnion = builder()
    self.capturedUnion = capturedUnion
    let nodeCapture: NodeCapture
    switch capturedUnion {
    case .a(let a):
      nodeCapture = NodeCapture(a)
    case .b(let b):
      nodeCapture = NodeCapture(b)
    case .c(let c):
      nodeCapture = NodeCapture(c)
    }
    self.capturedNode = nodeCapture
  }

  // MARK: Public

  public typealias Value = Union.Three<A, B, C>

  public static var type: RouteType { .union3 }

  public let defaultRecord: RouteRecord = .union3(.a(.invalid))

  public var fallback: Value {
    capturedUnion
  }

  @_spi(Implementation)
  public mutating func syncToState(field _: FieldID, in _: Runtime) throws -> [AnyScope] { [] }

  @_spi(Implementation)
  @TreeActor
  public func current(at fieldID: FieldID, in runtime: Runtime) throws -> Value {
    guard
      let record = runtime.getRouteRecord(at: fieldID),
      let scope = try? runtime
        .getScopes(at: fieldID).first
    else {
      assertionFailure()
      return capturedUnion
    }
    switch record {
    case .union3(let union3):
      switch union3 {
      case .a(let nodeID):
        assert(scope.nid == nodeID)
        if let node = scope.node as? A {
          return .a(node)
        }
      case .b(let nodeID):
        assert(scope.nid == nodeID)
        if let node = scope.node as? B {
          return .b(node)
        }
      case .c(let nodeID):
        assert(scope.nid == nodeID)
        if let node = scope.node as? C {
          return .c(node)
        }
      }
    default:
      break
    }
    assertionFailure()
    return capturedUnion
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

    switch capturedUnion {
    case .a:
      let scope = try connect(
        A.self,
        from: capturedNode,
        context: context,
        at: fieldID,
        in: runtime
      )
      runtime.updateRouteRecord(
        at: fieldID,
        to: .union3(.a(scope.nid))
      )
    case .b:
      let scope = try connect(
        B.self,
        from: capturedNode,
        context: context,
        at: fieldID,
        in: runtime
      )
      runtime.updateRouteRecord(
        at: fieldID,
        to: .union3(.b(scope.nid))
      )
    case .c:
      let scope = try connect(
        C.self,
        from: capturedNode,
        context: context,
        at: fieldID,
        in: runtime
      )
      runtime.updateRouteRecord(
        at: fieldID,
        to: .union3(.c(scope.nid))
      )
    }
  }

  public mutating func update(from other: Union3Router<A, B, C>) {
    if !(capturedUnion ~= other.capturedUnion) {
      self = other
    }
  }

  // MARK: Private

  private let capturedUnion: Union.Three<A, B, C>
  private let capturedNode: NodeCapture
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
        type: .union3,
        depth: context.depth
      )
    )
    return try initialized.connect()
  }

}

// MARK: - Route
extension Route {

  public init<A: Node, B: Node, C: Node>(wrappedValue: @autoclosure () -> Union.Three<A, B, C>)
    where Router == Union3Router<A, B, C>
  {
    self.init(defaultRouter: Union3Router<A, B, C>(builder: wrappedValue))
  }

}

extension Attach {
  public init<A: Node, B: Node, C: Node>(_ route: Route<Router>, to union: Union.Three<A, B, C>)
    where Router == Union3Router<A, B, C>
  {
    self.init(router: Router(builder: { union }), to: route)
  }
}
