import Foundation
import Intents

// MARK: - OnIntent

@TreeActor
public struct OnIntent: Rules {

  // MARK: Lifecycle

  public init<Step: IntentStepPayload>(
    _: Step.Type,
    _ stepAction: @TreeActor @escaping (_ step: Step) -> IntentAction
  ) {
    self.resolver = IntentStepResolver(id: UUID()) { step in
      if let step = try? step.decode(as: Step.self) {
        return .init(stepAction(step))
      } else {
        return .inapplicable
      }
    }
  }

  // MARK: Public

  public func act(for event: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    switch event {
    case .didStart:
      break
    case .didUpdate:
      break
    case .willStop:
      break
    case .handleIntent(let intent):
      let resolution = resolver.apply(step: intent.head)
      return .init(intentResolutions: [resolution])
    }
    return .init()
  }

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from _: Self,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  private let resolver: IntentStepResolver

}
