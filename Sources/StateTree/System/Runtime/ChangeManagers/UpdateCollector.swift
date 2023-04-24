// MARK: - UpdateCollector

struct UpdateCollector {
  var updates: [NodeID: NodeEvent] = [:]
}

extension UpdateCollector {
  func collectChanges() -> [NodeEvent] {
    updates
      .sorted { lhs, rhs in
        lhs.value.depthOrder < rhs.value.depthOrder
      }
      .map(\.value)
  }

  mutating func updated(id: NodeID, depth: Int) {
    // don't overwrite 'start' or 'stop' events as these are
    // more informative to clients.
    // however, if they lack depth info, add it.
    updates[id] = updates[id]?.addingDepthIfNeeded(depth) ?? .update(id: id, depth: depth)
  }

  mutating func started(id: NodeID, depth: Int?) {
    updates[id] = .start(id: id, depth: depth)
  }

  mutating func stopped(id: NodeID, depth: Int?) {
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
