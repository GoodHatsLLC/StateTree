import TreeActor

// MARK: - Union2Route

protocol Union2Route<A, B>: NodeUnionInternal {
  associatedtype A: Node
  associatedtype B: Node
  init?(asCaseContaining node: some Node)
}

// MARK: - Union.Two

extension Union {

  public enum Two<A: Node, B: Node>: Union2Route {
    case a(A)
    case b(B)

    // MARK: Lifecycle

    @TreeActor
    @_spi(Implementation)
    public init(record: RouteRecord, runtime: Runtime) throws {
      guard case .union2(let union2) = record
      else {
        throw InvalidRouteRecordError()
      }
      switch union2 {
      case .none:
        throw InvalidRouteRecordError()
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

    public init?(asCaseContaining node: some Node) {
      if let a = node as? A {
        self.init(a)
        return
      } else if let b = node as? B {
        self.init(b)
        return
      }
      return nil
    }

    init?(maybe: A?) {
      if let a = maybe {
        self = .a(a)
      } else {
        return nil
      }
    }

    init?(maybe: B?) {
      if let b = maybe {
        self = .b(b)
      } else {
        return nil
      }
    }

    init(_ a: A) { self = .a(a) }
    init(_ b: B) { self = .b(b) }

    // MARK: Public

    public static var routeType: RouteType { .union2 }
    @_spi(Implementation) public static var empty: RouteRecord { .union2(nil) }

    public var anyNode: any Node {
      switch self {
      case .a(let a): return a
      case .b(let b): return b
      }
    }

    public var a: A? {
      switch self {
      case .a(let a): return a
      case .b: return nil
      }
    }

    public var b: B? {
      switch self {
      case .b(let b): return b
      case .a: return nil
      }
    }

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

}
