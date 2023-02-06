// MARK: - EitherRule
@TreeActor
public enum EitherRule<RA: Rules, RB: Rules>: Rules {
  case ruleA(RA)
  case ruleB(RB)

  // MARK: Public

  public func act(for lifecycle: RuleLifecycle, with context: RuleContext) -> LifecycleResult {
    switch self {
    case .ruleA(let rA):
      return rA.act(for: lifecycle, with: context)
    case .ruleB(let rB):
      return rB.act(for: lifecycle, with: context)
    }
  }

  public mutating func applyRule(with context: RuleContext) throws {
    switch self {
    case .ruleA(var a):
      try a.applyRule(with: context)
      self = .ruleA(a)
    case .ruleB(var b):
      try b.applyRule(with: context)
      self = .ruleB(b)
    }
  }

  public mutating func removeRule(with context: RuleContext) throws {
    switch self {
    case .ruleA(var a):
      try a.removeRule(with: context)
      self = .ruleA(a)
    case .ruleB(var b):
      try b.removeRule(with: context)
      self = .ruleB(b)
    }
  }

  public mutating func updateRule(
    from new: Self,
    with context: RuleContext
  ) throws {
    switch (self, new) {
    case (.ruleA(var current), .ruleA(let new)):
      try current.updateRule(from: new, with: context)
      self = .ruleA(current)
    case (.ruleB(var current), .ruleB(let new)):
      try current.updateRule(from: new, with: context)
      self = .ruleB(current)
    case (_, _):
      try removeRule(with: context)
      self = new
      try applyRule(with: context)
    }
  }

}
