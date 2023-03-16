import Utilities

// MARK: - ErrorRule

@TreeActor
public struct ErrorRule: Rules {

  public mutating func applyRule(with _: RuleContext) throws { }

  public func act(for _: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    runtimeWarning("A rule threw an error when parsed")
    return .init()
  }

  public mutating func removeRule(with _: RuleContext) throws { }
  public mutating func updateRule(
    from _: ErrorRule,
    with _: RuleContext
  ) throws { }

  let error: any Error

}
