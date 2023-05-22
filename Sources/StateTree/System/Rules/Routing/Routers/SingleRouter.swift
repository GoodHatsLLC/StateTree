import TreeActor

public struct SingleRouter<NodeType: Node>: RouterType, OneRouterType {

  // MARK: Lifecycle

  init(builder: () -> NodeType) {
    self.fallback = builder()
  }

  // MARK: Public

  public typealias Value = NodeType

  public static var type: RouteType { .single }

  public let fallback: NodeType
  public let fallbackRecord: RouteRecord = .single(.invalid)

  public var current: NodeType {
    guard
      let connection = connection,
      let scope = try? connection.runtime
        .getScopes(at: connection.fieldID).first,
      let node = scope.node as? NodeType
    else {
      return fallback
    }
    return node
  }

  @TreeActor
  public func connectDefault() throws -> RouteRecord {
    guard
      let connection,
      let writeContext
    else {
      assertionFailure()
      return .single(.invalid)
    }
    let capture = NodeCapture(fallback)
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: connection.runtime
    )
    let initialized = try? uninitialized.initializeNode(
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
    guard
      let initialized,
      let scope = try? initialized.connect()
    else {
      assertionFailure()
      return .single(.invalid)
    }
    return .single(scope.nid)
  }

  public func apply(connection _: RouteConnection, writeContext _: RouterWriteContext) throws { }

  public func update(from _: SingleRouter<NodeType>) { }

  // MARK: Private

  private var connection: RouteConnection?
  private var writeContext: RouterWriteContext?

}
