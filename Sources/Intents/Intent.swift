
public struct Intent: Hashable, Codable, Sendable {

  // MARK: Lifecycle

  public init?(_ steps: any StepType...) {
    guard !steps.isEmpty
    else {
      return nil
    }
    var steps = steps.reversed().map { $0.asStep() }
    let last = steps.removeLast()
    self.head = last
    self.tailSteps = Array(steps)
  }

  private init? (
    steps: [Step]
  ) {
    guard !steps.isEmpty
    else {
      return nil
    }
    var steps = steps
    self.head = steps.removeLast()
    self.tailSteps = steps
  }

  // MARK: Public

  public let head: Step

  public var tail: Intent? {
    Intent(steps: tailSteps)
  }

  // MARK: Private

  private let tailSteps: [Step]

}
