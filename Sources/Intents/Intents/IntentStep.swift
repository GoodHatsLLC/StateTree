// MARK: - StepType

public protocol StepType {
  func asStep() -> Step
}

// MARK: - IntentStep

public protocol IntentStep: Codable, StepType {
  static var name: String { get }
}

extension IntentStep {
  func name() -> String {
    Self.name
  }
}

extension StepType where Self: IntentStep {
  public func asStep() -> Step {
    Step(self)
  }
}

// MARK: - Step + StepType

extension Step: StepType {
  public func asStep() -> Step {
    self
  }
}
