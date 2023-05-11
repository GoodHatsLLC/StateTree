import TreeActor

// MARK: - MaybeRule
@TreeActor
public struct MaybeRule<R: Rules>: Rules {

  // MARK: Public

  public mutating func applyRule(with context: RuleContext) throws {
    try optionalRules?.applyRule(with: context) ?? .none
  }

  public mutating func removeRule(with context: RuleContext) throws {
    try optionalRules?.removeRule(with: context) ?? .none
  }

  public func act(for lifecycle: RuleLifecycle, with context: RuleContext) -> LifecycleResult {
    optionalRules?.act(for: lifecycle, with: context) ?? .init()
  }

  public mutating func updateRule(
    from new: MaybeRule<R>,
    with context: RuleContext
  ) throws {
    switch (optionalRules, new.optionalRules) {
    case (.none, .some(var rules)):
      try rules.applyRule(with: context)
      optionalRules = rules
    case (.some(var current), .none):
      try current.removeRule(with: context)
      optionalRules = nil
    case (.some(var current), .some(let new)):
      try current.updateRule(from: new, with: context)
      optionalRules = current
    case (.none, .none):
      break
    }
  }

  // MARK: Internal

  var optionalRules: R?

}
