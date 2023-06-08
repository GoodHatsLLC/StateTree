import Foundation

public struct IntentStepResolver: Hashable {
  public init(id: UUID, action: @escaping (Step) -> IntentStepResolution) {
    self.id = id
    self.action = action
  }

  public static func == (lhs: IntentStepResolver, rhs: IntentStepResolver) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public let id: UUID
  private let action: (_ step: Step) -> IntentStepResolution

  public func apply(step: Step) -> IntentStepResolution {
    action(step)
  }
}
