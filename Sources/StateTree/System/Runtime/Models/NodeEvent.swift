public enum NodeEvent: Codable, CustomStringConvertible {
  case start(id: NodeID, depth: Int?)
  case update(id: NodeID, depth: Int)
  case stop(id: NodeID, depth: Int?)

  // MARK: Public

  public var description: String {
    switch self {
    case .start(let id, let depth):
      return "started node (id: \(id) depth: \(depth.map { String($0) } ?? "unknown"))"
    case .update(let id, let depth):
      return "updated node (id: \(id) depth: \(depth))"
    case .stop(let id, let depth):
      return "stopped node (id: \(id) depth: \(depth.map { String($0) } ?? "unknown"))"
    }
  }

  public var nodeID: NodeID {
    switch self {
    case .start(let id, _):
      return id
    case .update(let id, _):
      return id
    case .stop(let id, _):
      return id
    }
  }

  public var depthOrder: Int {
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

  // MARK: Internal

  func addingDepthIfNeeded(_ depth: Int) -> NodeEvent {
    switch self {
    case .start(id: let id, depth: .none):
      return .start(id: id, depth: depth)
    case .stop(id: let id, depth: .none):
      return .stop(id: id, depth: depth)
    case _:
      return self
    }
  }

}
