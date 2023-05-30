import TreeActor

// MARK: - Union2Router

public struct Union2Router<A: Node, B: Node>: RouterType {

  // MARK: Lifecycle

  init(builder: () -> Union.Two<A, B>) {
    let capturedUnion = builder()
    self.capturedUnion = capturedUnion
    let nodeCapture: NodeCapture
    switch capturedUnion {
    case .a(let a):
      nodeCapture = NodeCapture(a)
    case .b(let b):
      nodeCapture = NodeCapture(b)
    }
    self.capturedNode = nodeCapture
  }

  // MARK: Public

  public typealias Value = Union.Two<A, B>

  public static var type: RouteType { .union2 }

  public let defaultRecord: RouteRecord = .union2(.a(.invalid))

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
    case .union2(let union2):
      switch union2 {
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
        to: .union2(.a(scope.nid))
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
        to: .union2(.b(scope.nid))
      )
    }
  }

  public mutating func update(from other: Union2Router<A, B>) {
    if !(capturedUnion ~= other.capturedUnion) {
      self = other
    }
  }

  // MARK: Private

  private let capturedUnion: Union.Two<A, B>
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
        type: .union2,
        depth: context.depth
      )
    )
    return try initialized.connect()
  }

}

// MARK: - Route
extension Route {

  public init<A: Node, B: Node>(wrappedValue: @autoclosure () -> Union.Two<A, B>)
    where Router == Union2Router<A, B>
  {
    self.init(defaultRouter: Union2Router<A, B>(builder: wrappedValue))
  }

}

extension Attach {
  public init<A: Node, B: Node>(_ route: Route<Router>, to union: Union.Two<A, B>)
    where Router == Union2Router<A, B>
  {
    self.init(router: Router(builder: { union }), to: route)
  }
}
