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
  case single(NodeID)
  case union2(Union2)
  case union3(Union3)
  case maybeSingle(NodeID?)
  case maybeUnion2(Union2?)
  case maybeUnion3(Union3?)
  case list(List)

  // MARK: Public

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
    init(idMap: OrderedDictionary<LSID, NodeID>) {
      self.idMap = idMap
    }

    // MARK: Internal

    var nodeIDs: [NodeID] {
      Array(idMap.values)
    }

    func nodeID(matching route: RouteSource) -> NodeID? {
      route.identity.flatMap { idMap[$0] }
    }

    var idMap: OrderedDictionary<LSID, NodeID>
  }

  public var ids: [NodeID] {
    switch self {
    case .single(let single): return [single]
    case .union2(let union2): return [union2.id]
    case .union3(let union3): return [union3.id]
    case .maybeSingle(let single): return [single].compactMap { $0 }
    case .maybeUnion2(let union2): return [union2?.id].compactMap { $0 }
    case .maybeUnion3(let union3): return [union3?.id].compactMap { $0 }
    case .list(let list): return list.nodeIDs
    }
  }

  public var type: RouteType {
    switch self {
    case .single:
      return .single
    case .union2:
      return .union2
    case .union3:
      return .union3
    case .maybeSingle:
      return .maybeSingle
    case .maybeUnion2:
      return .maybeUnion2
    case .maybeUnion3:
      return .maybeUnion3
    case .list:
      return .list
    }
  }

  // MARK: Internal

  func nodeID(matching route: RouteSource) -> NodeID? {
    switch self {
    case .single(let nodeID):
      return nodeID
    case .union2(let union2):
      return union2.id
    case .union3(let union3):
      return union3.id
    case .maybeSingle(let nodeID):
      return nodeID
    case .maybeUnion2(let union2):
      return union2?.id
    case .maybeUnion3(let union3):
      return union3?.id
    case .list(let list):
      return list.nodeID(matching: route)
    }
  }
}
