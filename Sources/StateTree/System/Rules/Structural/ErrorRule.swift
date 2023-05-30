import TreeActor
import Utilities

// MARK: - ErrorRule

@TreeActor
public struct ErrorRule: Rules {

  public mutating func applyRule(with _: RuleContext) throws {
    runtimeWarning("A rule threw an error when parsed")
  }

  public func act(for _: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    runtimeWarning("A rule threw an error when parsed")
    return .init()
  }

  public mutating func removeRule(with _: RuleContext) throws { }
  public mutating func updateRule(
    from _: ErrorRule,
    with _: RuleContext
  ) throws { }

  public mutating func syncToState(with _: RuleContext) throws {
    runtimeWarning("A rule threw an error when parsed")
  }

  let error: any Error

}
