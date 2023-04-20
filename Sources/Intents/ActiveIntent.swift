struct ActiveIntent<ID: StepID>: Sendable, Hashable, Codable {
  init(intent: Intent, from stepID: ID) {
    self.lastStepID = stepID
    self.intent = intent
  }

  private(set) var lastStepID: ID
  private(set) var intent: Intent
  private(set) var usedStepIDs: Set<ID> = []

  mutating func recordNodeDependency(_ stepID: ID) {
    lastStepID = stepID
    usedStepIDs.insert(stepID)
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
