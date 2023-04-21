public struct ActiveIntent<ID: Sendable & Hashable & Codable>: Sendable, Hashable, Codable {
  public init(intent: Intent, from stepID: ID) {
    self.lastConsumerID = stepID
    self.intentPayload = intent
  }

  public private(set) var lastConsumerID: ID
  private var intentPayload: Intent?
  public var intent: Intent {
    intentPayload ?? Intent.invalid
  }

  public private(set) var consumerIDs: Set<ID> = []

  public var isValid: Bool {
    intentPayload != nil
  }

  public mutating func recordConsumer(_ consumerID: ID) {
    lastConsumerID = consumerID
    consumerIDs.insert(consumerID)
  }

  @discardableResult
  public mutating func popStep() -> (step: Step?, remainsValid: Bool) {
    defer { self.intentPayload = intentPayload?.tail }
    return (step: intentPayload?.head, remainsValid: intentPayload?.tail != nil)
  }

}
