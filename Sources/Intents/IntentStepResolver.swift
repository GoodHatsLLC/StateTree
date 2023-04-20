import Foundation

@_spi(Implementation)
public struct IntentStepResolver: Hashable {
  public static func == (lhs: IntentStepResolver, rhs: IntentStepResolver) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  init(
    id: UUID,
    action: @escaping (_ step: Step) -> StepResolutionInternal
  ) {
    self.id = id
    self.action = action
  }

  let id: UUID
  private let action: (_ step: Step) -> StepResolutionInternal

  func apply(step: Step) -> StepResolutionInternal {
    action(step)
  }
}
