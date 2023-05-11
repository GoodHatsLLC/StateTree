import TreeActor

// MARK: - UpdateCollector

struct UpdateCollector {
  var updates: [NodeID: NodeEvent] = [:]
  var stats = UpdateStats()
}

extension UpdateCollector {
  func collectChanges() -> (events: [NodeEvent], stats: UpdateStats) {
    let events = updates
      .sorted { lhs, rhs in
        lhs.value.depthOrder < rhs.value.depthOrder
      }
      .map(\.value)
    return (events: events, stats: stats)
  }

  mutating func updated(id: NodeID, depth: Int) {
    stats.nodeMap[id, default: .init(nodeID: id)].updates += 1
    // don't overwrite 'start' or 'stop' events as these are
    // more informative to clients.
    // however, if they lack depth info, add it.
    updates[id] = updates[id]?.addingDepthIfNeeded(depth) ?? .update(id: id, depth: depth)
  }

  mutating func started(id: NodeID, depth: Int?) {
    stats.nodeMap[id, default: .init(nodeID: id)].starts += 1
    updates[id] = .start(id: id, depth: depth)
  }

  mutating func stopped(id: NodeID, depth: Int?) {
    stats.nodeMap[id, default: .init(nodeID: id)].stops += 1
    switch updates[id] {
    case .none:
      updates[id] = .stop(id: id, depth: depth)
    case .some(.update(id: _, depth: let initialDepth)):
      updates[id] = .stop(id: id, depth: depth ?? initialDepth)
    case .some(.start(id: _, depth: _)):
      updates[id] = nil
    case .some(.stop(id: let id, depth: let initialDepth)):
      assertionFailure("stop events should not be reenqueued")
      updates[id] = .stop(id: id, depth: initialDepth ?? depth)
    }
  }
}
