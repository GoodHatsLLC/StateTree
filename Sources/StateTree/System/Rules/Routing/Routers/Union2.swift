import TreeActor

// MARK: - Union.Two

extension Union.Two: NodeUnion where A: Node, B: Node {
  public static var cardinality: NodeUnionCardinality {
    .three
  }

  public var anyNode: any Node {
    switch self {
    case .a(let a):
      return a
    case .b(let b):
      return b
    }
  }
}

extension Union.Two: NodeUnionInternal where A: Node, B: Node {


    // MARK: Lifecycle

    @TreeActor
    @_spi(Implementation)
    public init(record: RouteRecord, runtime: Runtime) throws {
      guard case .union2(let union2) = record
      else {
        throw InvalidRouteRecordError()
      }
      switch union2 {
      case .a(let nodeID):
        if
          let scope = try? runtime.getScope(for: nodeID),
          let node = scope.node as? A
        {
          self = .a(node)
          return
        }
      case .b(let nodeID):
        if
          let scope = try? runtime.getScope(for: nodeID),
          let node = scope.node as? B
        {
          self = .b(node)
          return
        }
      }
      throw InvalidRouteRecordError()
    }

    // MARK: Public

    @_spi(Implementation)
    public func idSet(from nodeID: NodeID) -> RouteRecord {
      switch self {
      case .a: return .union2(.a(nodeID))
      case .b: return .union2(.b(nodeID))
      }
    }

    @_spi(Implementation)
    public func matchesCase(of idSet: RouteRecord) -> Bool {
      guard case .union2(let union2ID) = idSet else {
        return false
      }
      switch (self, union2ID) {
      case (.a, .a): return true
      case (.b, .b): return true
      default: return false
      }
    }

    // MARK: Internal

    @TreeActor
    func initialize(
      from uninitialized: UninitializedNode,
      depth: Int,
      dependencies: DependencyValues,
      fieldID: FieldID
    ) throws
      -> AnyInitializedNode
    {
      let routeID = RouteSource(
        fieldID: fieldID,
        identity: nil,
        type: .union2
      )
      switch self {
      case .a:
        return try uninitialized
          .initialize(
            as: A.self,
            depth: depth,
            dependencies: dependencies,
            on: routeID
          ).erase()
      case .b:
        return try uninitialized
          .initialize(
            as: B.self,
            depth: depth,
            dependencies: dependencies,
            on: routeID
          ).erase()
      }
    }

    @TreeActor
    func initialize(
      from uninitialized: UninitializedNode,
      depth: Int,
      dependencies: DependencyValues,
      withKnownRecord record: NodeRecord
    ) throws
      -> AnyInitializedNode
    {
      switch self {
      case .a:
        return try uninitialized
          .initialize(
            as: A.self,
            depth: depth,
            dependencies: dependencies,
            record: record
          )
          .erase()
      case .b:
        return try uninitialized
          .initialize(
            as: B.self,
            depth: depth,
            dependencies: dependencies,
            record: record
          ).erase()
      }
    }

  }
