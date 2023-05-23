import TreeActor

// MARK: - Union2Router

public struct Union2Router<A: Node, B: Node>: RouterType {

  // MARK: Lifecycle

  init(union: Union.Two<A, B>) {
    self.capturedUnion = union
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

  public var current: Value {
    guard
      let connection = try? assumeConnection,
      let record = connection.runtime.getRouteRecord(at: connection.fieldID),
      let scope = try? connection.runtime
        .getScopes(at: connection.fieldID).first
    else {
      assertionFailure()
      return capturedUnion
    }
    switch record {
    case .single:
      break
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
    case .union3:
      break
    case .maybeSingle:
      break
    case .maybeUnion2:
      break
    case .maybeUnion3:
      break
    case .list:
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
        to: .union2(.a(scope.nid))
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
        to: .union2(.b(scope.nid))
      )
    }
  }

  public mutating func update(from other: Union2Router<A, B>) {
    if !(capturedUnion ~= other.capturedUnion) {
      var other = other
      other.hasApplied = false
      other.connection = connection
      other.writeContext = writeContext
      self = other
    }
  }

  // MARK: Private

  private let capturedUnion: Union.Two<A, B>
  private let capturedNode: NodeCapture
  private var hasApplied = false
  private var connection: RouteConnection?
  private var writeContext: RouterWriteContext?

  private var assumeConnection: RouteConnection {
    get throws {
      guard let connection
      else {
        assertionFailure()
        throw UnconnectedNodeError()
      }
      return connection
    }
  }

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
        type: .union2,
        depth: writeContext.depth
      )
    )
    return try initialized.connect()
  }

}

// MARK: - Route
extension Route {

  public init<A: Node, B: Node>(wrappedValue union: Union.Two<A, B>)
    where Router == Union2Router<A, B>
  {
    self.init(defaultRouter: Union2Router<A, B>(union: union))
  }
}

extension Attach {
  public init<A: Node, B: Node>(_ route: Route<Router>, to union: Union.Two<A, B>)
    where Router == Union2Router<A, B>
  {
    self.init(router: Router(union: union), to: route)
  }
}
