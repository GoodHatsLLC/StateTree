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

  public var current: Value {
    guard
      let connection = connection,
      let record = connection.runtime.getRouteRecord(at: connection.fieldID)
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
      case .c(let nodeID):
        guard
          let scope = try? connection.runtime
            .getScopes(at: connection.fieldID).first
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
        to: .maybeUnion3(nil)
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
        to: .maybeUnion3(.a(scope.nid))
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
        to: .maybeUnion3(.b(scope.nid))
      )
    case .c:
      let scope = try connect(
        C.self,
        from: capturedNode,
        connection: connection,
        writeContext: writeContext
      )
      connection.runtime.updateRouteRecord(
        at: connection.fieldID,
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
      var other = other
      other.hasApplied = false
      other.connection = connection
      other.writeContext = writeContext
      self = other
    }
  }

  // MARK: Private

  private let capturedUnion: Union.Three<A, B, C>?
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
        type: .maybeUnion3,
        depth: writeContext.depth
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

extension Attach {
  public init<A: Node, B: Node, C: Node>(_ route: Route<Router>, to union: Union.Three<A, B, C>?)
    where Router == MaybeUnion3Router<A, B, C>
  {
    self.init(router: Router(builder: { union }), to: route)
  }
}
