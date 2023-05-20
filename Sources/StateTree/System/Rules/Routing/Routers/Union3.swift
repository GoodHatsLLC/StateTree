import TreeActor

// MARK: - Union3Route

protocol Union3Route: NodeUnionInternal {
  associatedtype A: Node
  associatedtype B: Node
  associatedtype C: Node

  init?(payload: some Node)
}

// MARK: - Union.Three

extension Union.Three: NodeUnion where A: Node, B: Node, C: Node {

  public static var cardinality: NodeUnionCardinality {
    .three
  }

  public var anyNode: any Node {
    switch self {
    case .a(let a):
      return a
    case .b(let b):
      return b
    case .c(let c):
      return c
    }
  }
}

extension Union.Three: NodeUnionInternal where A: Node, B: Node, C: Node {}

extension Union.Three: Union3Route where A: Node, B: Node, C: Node {


    // MARK: Lifecycle

    @TreeActor
    @_spi(Implementation)
    public init(record: RouteRecord, runtime: Runtime) throws {
      if case .union3(let union3) = record {
        switch union3 {
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
        case .c(let nodeID):
          if
            let scope = try? runtime.getScope(for: nodeID),
            let node = scope.node as? C
          {
            self = .c(node)
            return
          }
        }
      }
      throw InvalidRouteRecordError()
    }


    @_spi(Implementation)
    public func idSet(from nodeID: NodeID) -> RouteRecord {
      switch self {
      case .a: return .union3(.a(nodeID))
      case .b: return .union3(.b(nodeID))
      case .c: return .union3(.c(nodeID))
      }
    }

    @_spi(Implementation)
    public func matchesCase(of idSet: RouteRecord) -> Bool {
      guard case .union3(let union3ID) = idSet else {
        return false
      }

      switch (self, union3ID) {
      case (.a, .a): return true
      case (.b, .b): return true
      case (.c, .c): return true
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
        type: .union3
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
      case .c:
        return try uninitialized
          .initialize(
            as: C.self,
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
      case .c:
        return try uninitialized
          .initialize(
            as: C.self,
            depth: depth,
            dependencies: dependencies,
            record: record
          ).erase()
      }
    }
}
