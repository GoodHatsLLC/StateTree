// MARK: - NodeChanges

public enum NodeChange: Hashable, Sendable {

  case started(NodeID)
  case updated(NodeID)
  case stopped(NodeID)

  // MARK: Public

  public enum MetaData: Hashable {
    case start(id: NodeID, depth: Int?)
    case update(id: NodeID, depth: Int)
    case stop(id: NodeID, depth: Int?)

    // MARK: Internal

    var depthOrder: Int {
      switch self {
      case .start(id: _, depth: .none):
        return Int.min
      case .start(id: _, depth: .some(let depth)):
        return depth
      case .stop(id: _, depth: .none):
        return Int.max
      case .stop(id: _, depth: .some(let depth)):
        return depth
      case .update(id: _, depth: let depth):
        return depth
      }
    }

    func addingDepthIfNeeded(_ depth: Int) -> MetaData {
      switch self {
      case .start(id: let id, depth: .none):
        return .start(id: id, depth: depth)
      case .stop(id: let id, depth: .none):
        return .stop(id: id, depth: depth)
      case _:
        return self
      }
    }

    func asChange(_ id: NodeID) -> NodeChange {
      switch self {
      case .start: return .started(id)
      case .stop: return .stopped(id)
      case .update: return .updated(id)
      }
    }
  }

  // MARK: Internal

  var id: NodeID {
    switch self {
    case .started(let nodeID):
      return nodeID
    case .updated(let nodeID):
      return nodeID
    case .stopped(let nodeID):
      return nodeID
    }
  }
}
