import TreeActor

public struct SingleRouter<NodeType: Node>: RouterType, OneRouterType {

  // MARK: Lifecycle

  init(builder: () -> NodeType) {
    self.capturedNode = builder()
  }

  // MARK: Public

  public typealias Value = NodeType

  public static var type: RouteType { .single }

  public let defaultRecord: RouteRecord = .single(.invalid)

  public var fallback: NodeType {
    capturedNode
  }

  public var current: NodeType {
    guard
      let connection = connection,
      let scope = try? connection.runtime
        .getScopes(at: connection.fieldID).first,
      let node = scope.node as? NodeType
    else {
      return capturedNode
    }
    return node
  }

  public mutating func apply(connection: RouteConnection, writeContext: RouterWriteContext) throws {
    guard !hasApplied
    else {
      return
    }
    hasApplied = true
    let capture = NodeCapture(capturedNode)
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
    if let node = try? initialized?.connect() {
      connection.runtime.updateRouteRecord(at: connection.fieldID, to: .single(node.nid))
    } else {
      assertionFailure()
    }
  }

  public mutating func update(from other: SingleRouter<NodeType>) {
    var other = other
    other.connection = connection
    other.writeContext = writeContext
    other.hasApplied = false
    self = other
  }

  // MARK: Private

  private let capturedNode: NodeType
  private var hasApplied = false
  private var connection: RouteConnection?
  private var writeContext: RouterWriteContext?

}
