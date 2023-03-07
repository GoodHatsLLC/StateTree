// MARK: - Union3Route

protocol Union3Route: NodeUnionInternal {
  associatedtype A: Node
  associatedtype B: Node
  associatedtype C: Node

  init?(asCaseContaining: some Node)
}

// MARK: - Union.Three

extension Union {

  public enum Three<A: Node, B: Node, C: Node>: Union3Route {

    case a(A)
    case b(B)
    case c(C)

    // MARK: Lifecycle

    @TreeActor
    @_spi(Implementation)
    public init?(record: RouteRecord, runtime: Runtime) {
      if case .union3(let union3) = record, let union3 {
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
      return nil
    }

    public init?(asCaseContaining node: some Node) {
      if let a = node as? A {
        self.init(a)
      } else if let b = node as? B {
        self.init(b)
      } else if let c = node as? C {
        self.init(c)
      } else {
        return nil
      }
    }

    public init?(maybe: A?) {
      if let a = maybe {
        self = .a(a)
      } else {
        return nil
      }
    }

    public init?(maybe: B?) {
      if let b = maybe {
        self = .b(b)
      } else {
        return nil
      }
    }

    public init?(maybe: C?) {
      if let c = maybe {
        self = .c(c)
      } else {
        return nil
      }
    }

    public init(_ a: A) { self = .a(a) }
    public init(_ b: B) { self = .b(b) }
    public init(_ c: C) { self = .c(c) }

    // MARK: Public

    public static var empty: RouteRecord { .union3(nil) }

    public var anyNode: any Node {
      switch self {
      case .a(let a): return a
      case .b(let b): return b
      case .c(let c): return c
      }
    }

    public var a: A? {
      switch self {
      case .a(let a): return a
      case .b: return nil
      case .c: return nil
      }
    }

    public var b: B? {
      switch self {
      case .b(let b): return b
      case .a: return nil
      case .c: return nil
      }
    }

    public var c: C? {
      switch self {
      case .c(let c): return c
      case .a: return nil
      case .b: return nil
      }
    }

    public func idSet(from nodeID: NodeID) -> RouteRecord {
      switch self {
      case .a: return .union3(.a(nodeID))
      case .b: return .union3(.b(nodeID))
      case .c: return .union3(.c(nodeID))
      }
    }

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
        identity: uninitialized.capture.anyNode.cuid,
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
}
