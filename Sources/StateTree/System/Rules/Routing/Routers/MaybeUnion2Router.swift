import TreeActor

// MARK: - MaybeUnion2Router

public struct MaybeUnion2Router<A: Node, B: Node>: RouterType {

  // MARK: Lifecycle

  init(builder: () -> Union.Two<A, B>?) {
    let capturedUnion = builder()
    self.capturedUnion = capturedUnion
    let nodeCapture: NodeCapture?
    switch capturedUnion {
    case nil:
      nodeCapture = nil
    case .a(let a):
      nodeCapture = NodeCapture(a)
    case .b(let b):
      nodeCapture = NodeCapture(b)
    }
    self.capturedNode = nodeCapture
  }

  // MARK: Public

  public typealias Value = Union.Two<A, B>?

  public static var type: RouteType { .maybeUnion2 }

  public let defaultRecord: RouteRecord = .maybeUnion2(nil)

  public var fallback: Value {
    capturedUnion
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
    guard case .maybeUnion2(let maybeUnion2Record) = record
    else {
      assertionFailure()
      throw IncorrectRouterTypeError()
    }
    guard let requiredCase = maybeUnion2Record
    else {
      assert(capturedNode == nil)
      return []
    }
    guard
      let capture = capturedNode,
      let record = runtime.getRecord(requiredCase.id)
    else {
      throw InvalidSyncFailure()
    }
    if (try? runtime.getScope(for: requiredCase.id)) != nil {
      return []
    }
    let uninitialized = UninitializedNode(capture: capture, runtime: runtime)
    switch requiredCase {
    case .a:
      return [
        try uninitialized
          .reinitializeNode(
            asType: A.self,
            from: record,
            dependencies: context.dependencies,
            on: .init(fieldID: fieldID, identity: nil, type: .maybeUnion2, depth: context.depth)
          )
          .connect()
          .erase(),
      ]
    case .b:
      return [
        try uninitialized
          .reinitializeNode(
            asType: B.self,
            from: record,
            dependencies: context.dependencies,
            on: .init(fieldID: fieldID, identity: nil, type: .maybeUnion2, depth: context.depth)
          )
          .connect()
          .erase(),
      ]
    }
  }

  @_spi(Implementation)
  @TreeActor
  public func current(at fieldID: FieldID, in runtime: Runtime) throws -> Value {
    guard let record = runtime.getRouteRecord(at: fieldID)
    else {
      assertionFailure()
      return capturedUnion
    }
    switch record {
    case .maybeUnion2(let union2):
      switch union2 {
      case nil:
        return nil
      case .a(let nodeID):
        guard
          let scope = try? runtime
            .getScopes(at: fieldID).first
        else {
          break
        }
        assert(scope.nid == nodeID)
        if let node = scope.node as? A {
          return .a(node)
        }
      case .b(let nodeID):
        guard
          let scope = try? runtime
            .getScopes(at: fieldID).first
        else {
          break
        }
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
    guard let capturedNode, let capturedUnion
    else {
      runtime.updateRouteRecord(
        at: fieldID,
        to: .maybeUnion2(nil)
      )
      return
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
        to: .maybeUnion2(.a(scope.nid))
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
        to: .maybeUnion2(.b(scope.nid))
      )
    }
  }

  public mutating func update(from other: MaybeUnion2Router<A, B>) {
    var shouldUpdate = false
    if let capturedUnion, let otherUnion = other.capturedUnion, !(capturedUnion ~= otherUnion) {
      shouldUpdate = true
    } else if (capturedUnion == nil) != (other.capturedUnion == nil) {
      shouldUpdate = true
    }
    if shouldUpdate {
      self = other
    }
  }

  // MARK: Private

  private let capturedUnion: Union.Two<A, B>?
  private let capturedNode: NodeCapture?
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
        type: .maybeUnion2,
        depth: context.depth
      )
    )
    return try initialized.connect()
  }

}

// MARK: - Route
extension Route {

  public init<A: Node, B: Node>(wrappedValue: @autoclosure () -> Union.Two<A, B>?)
    where Router == MaybeUnion2Router<A, B>
  {
    self.init(defaultRouter: MaybeUnion2Router<A, B>(builder: wrappedValue))
  }

}

extension Serve {
  public init<A: Node, B: Node>(_ union: Union.Two<A, B>?, at route: Route<Router>)
    where Router == MaybeUnion2Router<A, B>
  {
    self.init(router: MaybeUnion2Router(builder: { union }), at: route)
  }
}
