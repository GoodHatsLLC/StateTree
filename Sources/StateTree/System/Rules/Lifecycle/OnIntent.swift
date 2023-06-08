import Foundation
import Intents
import TreeActor

// MARK: - OnIntent

/// Register an ``Intent`` Step handler.
///
/// Register the type of payload expected and return an action or a pending state.
///
/// The handler is called when:
/// * No lower level handler has acted for the step.
/// * Any previous step in the intent was handled by an ancestor node.
/// * The step's name matches the registered type's `name` field.
/// * The step's payload can be deserialized to the registered type.
///
/// If a pending state is returned, the handler will be called again for the payload
/// when the node's state changes—unless another node has handled the step.
///
/// ```swift
/// OnIntent(PendingNodeStep.self) { step in
///   if /* should act now */ {
///     return .act { shouldRoute = step.shouldRoute }
///   } else {
///     return .pend
///   }
/// }
/// ```
public struct OnIntent: Rules {

  // MARK: Lifecycle

  /// Register an ``Intent`` Step handler.
  ///
  /// - Parameter payloadType: The type the step's payload must match for the handler to fire.
  /// (A payload matches if it's name matche the types static `name` field, and it can be
  /// deserialized to the type.)
  /// - Parameter handler: The handler for a matching payload. It must return either an action or a
  /// pending state.
  public init<Step: StepPayload>(
    _: Step.Type,
    handler: @TreeActor @escaping (_ step: Step) -> IntentAction
  ) {
    self.resolver = IntentStepResolver(id: UUID()) { step in
      if let step = try? step.getPayload(as: Step.self) {
        return .init(handler(step))
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
      let resolution = resolver.apply(step: intent.head!)
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

  public mutating func syncToState(with _: RuleContext) throws { }

  // MARK: Private

  private let resolver: IntentStepResolver

}
