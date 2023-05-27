import TreeActor

// MARK: - EmptyRule

@TreeActor
public struct EmptyRule: Rules {
  public func act(for _: RuleLifecycle, with _: RuleContext) -> LifecycleResult { .init() }
  public mutating func applyRule(with _: RuleContext) throws { }
  public mutating func removeRule(with _: RuleContext) throws { }
  public mutating func updateRule(
    from _: EmptyRule,
    with _: RuleContext
  ) throws { }

  public mutating func syncRuntime(with _: RuleContext) throws { }

  nonisolated init() { }

}

extension Rules where Self == EmptyRule {
  public static var none: EmptyRule { EmptyRule() }
}
