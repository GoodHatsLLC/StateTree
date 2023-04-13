import Behavior

// MARK: - TreeEvent

public enum TreeEvent: TreeState {

  case treeStarted
  case treeStopped
  case nodeStarted(NodeID)
  case nodeUpdated(NodeID)
  case nodeStopped(NodeID)
  case behaviorCreated(BehaviorID)
  case behaviorStarted(BehaviorID)
  case behaviorFinished(BehaviorID)

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

    func asTreeEvent(_ id: NodeID) -> TreeEvent {
      switch self {
      case .start: return .nodeStarted(id)
      case .stop: return .nodeStopped(id)
      case .update: return .nodeUpdated(id)
      }
    }
  }

  public var nodeID: NodeID? {
    switch self {
    case .nodeStarted(let nodeID):
      return nodeID
    case .nodeUpdated(let nodeID):
      return nodeID
    case .nodeStopped(let nodeID):
      return nodeID
    default:
      return nil
    }
  }

  public var behaviorID: BehaviorID? {
    switch self {
    case .behaviorCreated(let id),
         .behaviorFinished(let id),
         .behaviorStarted(let id):
      return id
    default:
      return nil
    }
  }
}

extension BehaviorEvent {
  func asTreeEvent() -> TreeEvent {
    switch self {
    case .created(let behaviorID):
      return .behaviorCreated(behaviorID)
    case .started(let behaviorID):
      return .behaviorStarted(behaviorID)
    case .finished(let behaviorID):
      return .behaviorFinished(behaviorID)
    }
  }
}
