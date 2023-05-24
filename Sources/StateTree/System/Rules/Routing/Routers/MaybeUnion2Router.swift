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

  public var current: Value {
    guard
      let connection = connection,
      let record = connection.runtime.getRouteRecord(at: connection.fieldID)
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
          let scope = try? connection.runtime
            .getScopes(at: connection.fieldID).first
        else {
          break
        }
        assert(scope.nid == nodeID)
        if let node = scope.node as? A {
          return .a(node)
        }
      case .b(let nodeID):
        guard
          let scope = try? connection.runtime
            .getScopes(at: connection.fieldID).first
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

  public mutating func apply(connection: RouteConnection, writeContext: RouterWriteContext) throws {
    guard !hasApplied
    else {
      return
    }
    hasApplied = true

    self.connection = connection
    self.writeContext = writeContext

    guard let capturedNode, let capturedUnion
    else {
      connection.runtime.updateRouteRecord(
        at: connection.fieldID,
        to: .maybeUnion2(nil)
      )
      return
    }
    switch capturedUnion {
    case .a:
      let scope = try connect(
        A.self,
        from: capturedNode,
        connection: connection,
        writeContext: writeContext
      )
      connection.runtime.updateRouteRecord(
        at: connection.fieldID,
        to: .maybeUnion2(.a(scope.nid))
      )
    case .b:
      let scope = try connect(
        B.self,
        from: capturedNode,
        connection: connection,
        writeContext: writeContext
      )
      connection.runtime.updateRouteRecord(
        at: connection.fieldID,
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
      var other = other
      other.hasApplied = false
      other.connection = connection
      other.writeContext = writeContext
      self = other
    }
  }

  // MARK: Private

  private let capturedUnion: Union.Two<A, B>?
  private let capturedNode: NodeCapture?
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
        type: .maybeUnion2,
        depth: writeContext.depth
      )
    )
    return try initialized.connect()
  }

}

// MARK: - Route
extension Route {

  // MARK: Lifecycle

  public init<A: Node, B: Node>(wrappedValue: @autoclosure () -> Union.Two<A, B>?)
    where Router == MaybeUnion2Router<A, B>
  {
    self.init(defaultRouter: MaybeUnion2Router<A, B>(builder: wrappedValue))
  }

  // MARK: Public

  @TreeActor
  public func route<A: Node, B: Node>(builder: () -> Union.Two<A, B>?) -> Attach<Router>
    where Router == MaybeUnion2Router<A, B>
  {
    Attach<Router>(router: MaybeUnion2Router(builder: builder), to: self)
  }
}

extension Attach {
  public init<A: Node, B: Node>(_ route: Route<Router>, to union: Union.Two<A, B>?)
    where Router == MaybeUnion2Router<A, B>
  {
    self.init(router: Router(builder: { union }), to: route)
  }
}
