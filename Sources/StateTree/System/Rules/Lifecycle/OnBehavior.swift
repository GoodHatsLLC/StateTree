import Disposable
import Emitter
#if canImport(Combine)
import struct Combine.AnyPublisher
import protocol Combine.Publisher
#endif

// MARK: - OnBehavior

@TreeActor
public struct OnBehavior<Value: Sendable>: Rules {

  // MARK: Public

  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    switch lifecycle {
    case .didStart:
      break
//      let behavior = behaviorBuilder()
//      behavior
//        .erase()
//        .stage(on: stage)
//      behavior.run(on: context.scope)
//      return LifecycleResult(behaviors: [behavior])
    case .didUpdate:
      break
    case .willStop:
      stage.dispose()
    case .handleIntent:
      break
    }
    return .init()
  }

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from _: OnBehavior<Value>,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  ///  private let behaviorBuilder: () -> PreparedBehavior
  private let stage = DisposableStage()

}
