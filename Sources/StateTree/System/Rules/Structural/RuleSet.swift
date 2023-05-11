import TreeActor

// MARK: - RuleSet
@TreeActor
public struct RuleSet<R: Rules>: Rules {

  public init(@RuleBuilder rules: () -> R) {
    self.rules = rules()
  }

  public func act(for lifecycle: RuleLifecycle, with context: RuleContext) -> LifecycleResult {
    rules.act(for: lifecycle, with: context)
  }

  public mutating func applyRule(with context: RuleContext) throws {
    try rules.applyRule(with: context)
  }

  public mutating func removeRule(with context: RuleContext) throws {
    try rules.removeRule(with: context)
  }

  public mutating func updateRule(
    from new: RuleSet<R>,
    with context: RuleContext
  ) throws {
    try rules.updateRule(from: new.rules, with: context)
  }

  var rules: R

}
