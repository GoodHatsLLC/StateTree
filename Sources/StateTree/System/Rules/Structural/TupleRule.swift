import TreeActor

// MARK: - TupleRule
@TreeActor
public struct TupleRule<M1: Rules, M2: Rules>: Rules {

  // MARK: Public

  public func act(for lifecycle: RuleLifecycle, with context: RuleContext) -> LifecycleResult {
    rule1.act(for: lifecycle, with: context) + rule2.act(for: lifecycle, with: context)
  }

  public mutating func applyRule(with context: RuleContext) throws {
    try rule1.applyRule(with: context)
    try rule2.applyRule(with: context)
  }

  public mutating func removeRule(with context: RuleContext) throws {
    try rule1.removeRule(with: context)
    try rule2.removeRule(with: context)
  }

  public mutating func updateRule(
    from new: TupleRule<M1, M2>,
    with context: RuleContext
  ) throws {
    try rule1.updateRule(from: new.rule1, with: context)
    try rule2.updateRule(from: new.rule2, with: context)
  }

  public mutating func syncToState(with context: RuleContext) throws {
    try rule1.syncToState(with: context)
    try rule2.syncToState(with: context)
  }

  // MARK: Internal

  var rule1: M1
  var rule2: M2
}
