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
    action: @TreeActor @escaping (_ step: Step) -> StepResolutionInternal
  ) {
    self.id = id
    self.action = action
  }

  let id: UUID
  private let action: @TreeActor (_ step: Step) -> StepResolutionInternal
  @TreeActor
  func apply(step: Step) -> StepResolutionInternal {
    action(step)
  }
}
