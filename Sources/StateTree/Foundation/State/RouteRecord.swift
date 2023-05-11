import OrderedCollections
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
public enum RouteRecord: Codable {
  case single(Single?)
  case union2(Union2?)
  case union3(Union3?)
  case list(List?)

  // MARK: Public

  public struct Single: Codable {
    var id: NodeID
  }

  public enum Union2: Codable {
    case a(NodeID)
    case b(NodeID)
    var id: NodeID {
      switch self {
      case .a(let nodeID): return nodeID
      case .b(let nodeID): return nodeID
      }
    }
  }

  public enum Union3: Codable {
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

  public struct List: Codable {

    // MARK: Lifecycle

    init(nodeIDs: [NodeID]) {
      self.idMap = Self.identityDict(nodeIDs: nodeIDs)
    }

    init(idMap: OrderedDictionary<CUID, NodeID>) {
      self.idMap = idMap
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      let nids = try container.decode([NodeID].self)
      self.idMap = Self.identityDict(nodeIDs: nids)
    }

    // MARK: Public

    public static func identityDict(nodeIDs: [NodeID]) -> OrderedDictionary<CUID, NodeID> {
      let pairs: [(CUID, NodeID)] = nodeIDs
        .compactMap { nid in
          if let cuid = nid.cuid {
            return (cuid, nid)
          } else {
            return nil
          }
        }
      return pairs
        .reduce(into: OrderedDictionary<CUID, NodeID>()) { acc, curr in
          acc[curr.0] = curr.1
        }
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(Array(idMap.values))
    }

    // MARK: Internal

    var nodeIDs: [NodeID] {
      Array(idMap.values)
    }

    func nodeID(matching route: RouteSource) -> NodeID? {
      route.identity.flatMap { idMap[$0] }
    }

    // MARK: Private

    private var idMap: OrderedDictionary<CUID, NodeID>
  }

  public var ids: [NodeID] {
    switch self {
    case .single(let single): return (single?.id).map { [$0] } ?? []
    case .union2(let union2): return (union2?.id).map { [$0] } ?? []
    case .union3(let union3): return (union3?.id).map { [$0] } ?? []
    case .list(let list): return list?.nodeIDs ?? []
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
