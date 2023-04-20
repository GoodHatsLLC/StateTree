public struct ActiveIntent<ID: StepID>: Sendable, Hashable, Codable {
  public init(intent: Intent, from stepID: ID) {
    self.lastStepID = stepID
    self.intent = intent
  }

  public private(set) var lastStepID: ID
  public private(set) var intent: Intent
  public private(set) var usedStepIDs: Set<ID> = []

  public mutating func recordStepDependency(_ stepID: ID) {
    lastStepID = stepID
    usedStepIDs.insert(stepID)
  }

  public mutating func popStepReturningPendingState() -> Bool {
    if let intent = intent.tail {
      self.intent = intent
      return true
    } else {
      return false
    }
  }
}
