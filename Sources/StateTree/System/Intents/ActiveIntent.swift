import TreeState

struct ActiveIntent: TreeState {
  init(intent: Intent, from nodeID: NodeID) {
    self.lastNodeID = nodeID
    self.intent = intent
  }

  private(set) var lastNodeID: NodeID
  private(set) var intent: Intent
  private(set) var usedNodeIDs: Set<NodeID> = []

  mutating func recordNodeDependency(_ nodeID: NodeID) {
    lastNodeID = nodeID
    usedNodeIDs.insert(nodeID)
  }

  mutating func popStepReturningPendingState() -> Bool {
    if let intent = intent.tail {
      self.intent = intent
      return true
    } else {
      return false
    }
  }
}
