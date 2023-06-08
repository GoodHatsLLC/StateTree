public struct Step: StepType, Sendable {
  public init(_ step: some StepType) {
    self.contained = step.erase()
  }

  private let contained: AnyStep
  public func getName() -> String {
    contained.getName()
  }

  public func getPayload<T>(as _: T.Type) throws -> T where T: StepPayload {
    let name = contained.getName()
    guard T.name == name
    else {
      throw UnmatchedIntentName(target: T.name, payload: name)
    }
    return try contained.getPayload(as: T.self)
  }

  public func erase() -> AnyStep {
    contained.erase()
  }

}
