import Behaviors

// MARK: - RuleContext

public struct RuleContext {
  let runtime: Runtime
  let scope: AnyScope
  var dependencies: DependencyValues
  let depth: Int
}

// MARK: - RuleLifecycle

public enum RuleLifecycle {
  case didStart
  case didUpdate
  case willStop
  case handleIntent(Intent)
}

// MARK: - LifecycleResult

public struct LifecycleResult {
  init(
    intentResolutions: [StepResolutionInternal] = []
  ) {
    self.intentResolutions = intentResolutions
  }

  let intentResolutions: [StepResolutionInternal]

  public static func + (lhs: LifecycleResult, rhs: LifecycleResult) -> LifecycleResult {
    LifecycleResult(
      intentResolutions: lhs.intentResolutions + rhs.intentResolutions
    )
  }
}

// MARK: - Rules

@TreeActor
public protocol Rules {
  func act(for: RuleLifecycle, with: RuleContext) -> LifecycleResult
  /// Apply a new rule
  mutating func applyRule(with: RuleContext) throws
  /// Remove an existing rule
  mutating func removeRule(with: RuleContext) throws
  /// Update a rule from a new version of itself
  mutating func updateRule(from: Self, with: RuleContext) throws
}
