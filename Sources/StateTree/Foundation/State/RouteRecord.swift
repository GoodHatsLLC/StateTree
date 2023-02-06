/// The underlying StateTree representation of the identity of a routed node.
///
/// `@Route` (``Route``) fields may be of different types such as:
/// - Single node-types, only ever routing one type of ``Node``
/// - Union node types, potentially routing one of a known set of possible types of ``Node``
///
/// When a routed node could be one of multiple types, StateTree tracks the routed type as a
/// case value of this enum — which corresponds to a case value in the ``UnionRouter``'s
/// ``NodeUnion``.
///
/// > Note: Each ``RouterType`` implementation used in StateTree should be represented by a
/// `RouteRecord` case.
///
/// > Discussion:
/// For example a route to one of two types,`NodeA` or `NodeB` might be represented by
/// `.a(<NodeID>)`
/// which would in turn correspond to a known `Node` type of the router's`Union.Two<NodeA, NodeB>`.
public enum RouteRecord: TreeState {
  case single(Single?)
  case union2(Union2?)
  case union3(Union3?)
  case list(List?)

  // MARK: Public

  public struct Single: TreeState {
    var id: NodeID
  }

  public enum Union2: TreeState {
    case a(NodeID)
    case b(NodeID)
    var id: NodeID {
      switch self {
      case .a(let nodeID): return nodeID
      case .b(let nodeID): return nodeID
      }
    }
  }

  public enum Union3: TreeState {
    case a(NodeID)
    case b(NodeID)
    case c(NodeID)
    var id: NodeID {
      switch self {
      case .a(let nodeID): return nodeID
      case .b(let nodeID): return nodeID
      case .c(let nodeID): return nodeID
      }
    }
  }

  public struct List: TreeState {

    // MARK: Lifecycle

    init(ids: [String: NodeID]) {
      self.ids = ids
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      let pairs = try container.decode([IDPair].self)
      self.ids = pairs.reduce(into: [String: NodeID]()) { partialResult, pair in
        partialResult[pair.key] = pair.val
      }
    }

    // MARK: Public

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      let pairs = ids.map { IDPair(key: $0.key, val: $0.value) }.sorted(by: { $0.key < $1.key })
      try container.encode(pairs)
    }

    // MARK: Internal

    struct IDPair: TreeState {
      var key: String
      var val: NodeID
    }

    enum CodingKeys: CodingKey {
      case ids
    }

    func nodeID(matching route: RouteSource) -> NodeID? {
      route.identity.flatMap { ids[$0] }
    }

    func sortedNodeIDs() -> [NodeID] {
      ids
        .map { (sortKey: $0.key, value: $0.value) }
        .sorted { lhs, rhs in
          lhs.sortKey < rhs.sortKey
        }
        .map(\.value)
    }

    // MARK: Private

    private var ids: [String: NodeID]
  }

  public var ids: [NodeID] {
    switch self {
    case .single(let single): return (single?.id).map { [$0] } ?? []
    case .union2(let union2): return (union2?.id).map { [$0] } ?? []
    case .union3(let union3): return (union3?.id).map { [$0] } ?? []
    case .list(let list): return list?.sortedNodeIDs() ?? []
    }
  }

  // MARK: Internal

  func nodeID(matching route: RouteSource) -> NodeID? {
    switch (route.identity, self) {
    case (.none, .single(let single)): return single?.id
    case (.none, .union2(let union2)): return union2?.id
    case (.none, .union3(let union3)): return union3?.id
    case (.some, .list(let list)): return list?.nodeID(matching: route)
    default: return nil
    }
  }
}
