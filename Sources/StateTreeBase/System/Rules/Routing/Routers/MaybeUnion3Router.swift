import TreeActor

// MARK: - MaybeUnion3Router

public struct MaybeUnion3Router<A: Node, B: Node, C: Node>: RouterType {

  // MARK: Lifecycle

  init(builder: () -> Union.Three<A, B, C>?) {
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
    case .c(let c):
      nodeCapture = NodeCapture(c)
    }
    self.capturedNode = nodeCapture
  }

  // MARK: Public

  public typealias Value = Union.Three<A, B, C>?

  public static var type: RouteType { .maybeUnion3 }

  public let defaultRecord: RouteRecord = .maybeUnion3(nil)

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
    guard case .maybeUnion3(let maybeUnion3Record) = record
    else {
      assertionFailure()
      throw IncorrectRouterTypeError()
    }
    guard let requiredCase = maybeUnion3Record
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
    let uninitialized = UninitializedNode(capture: capture, runtime: runtime)
    switch requiredCase {
    case .a:
      return [
        try uninitialized
          .reinitializeNode(
            asType: A.self,
            from: record,
            dependencies: context.dependencies,
            on: .init(fieldID: fieldID, identity: nil, type: .maybeUnion3, depth: context.depth)
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
            on: .init(fieldID: fieldID, identity: nil, type: .maybeUnion3, depth: context.depth)
          )
          .connect()
          .erase(),
      ]
    case .c:
      return [
        try uninitialized
          .reinitializeNode(
            asType: C.self,
            from: record,
            dependencies: context.dependencies,
            on: .init(fieldID: fieldID, identity: nil, type: .maybeUnion3, depth: context.depth)
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
    case .maybeUnion3(let union3):
      switch union3 {
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
      case .c(let nodeID):
        guard
          let scope = try? runtime
            .getScopes(at: fieldID).first
        else {
          break
        }
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
    guard let capturedNode, let capturedUnion
    else {
      runtime.updateRouteRecord(
        at: fieldID,
        to: .maybeUnion3(nil)
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
        to: .maybeUnion3(.a(scope.nid))
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
        to: .maybeUnion3(.b(scope.nid))
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
        to: .maybeUnion3(.c(scope.nid))
      )
    }
  }

  public mutating func update(from other: MaybeUnion3Router<A, B, C>) {
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

  private let capturedUnion: Union.Three<A, B, C>?
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
        type: .maybeUnion3,
        depth: context.depth
      )
    )
    return try initialized.connect()
  }

}

// MARK: - Route
extension Route {

  public init<A: Node, B: Node, C: Node>(wrappedValue: @autoclosure () -> Union.Three<A, B, C>?)
    where Router == MaybeUnion3Router<A, B, C>
  {
    self.init(defaultRouter: MaybeUnion3Router<A, B, C>(builder: wrappedValue))
  }

}

extension Serve {
  public init<A: Node, B: Node, C: Node>(_ union: Union.Three<A, B, C>?, at route: Route<Router>)
    where Router == MaybeUnion3Router<A, B, C>
  {
    self.init(router: MaybeUnion3Router(builder: { union }), at: route)
  }
}
