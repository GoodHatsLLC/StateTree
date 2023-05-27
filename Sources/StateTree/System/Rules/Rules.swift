import Behavior
import Intents
import TreeActor

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
    intentResolutions: [IntentStepResolution] = []
  ) {
    self.intentResolutions = intentResolutions
  }

  let intentResolutions: [IntentStepResolution]

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
  /// Sync the runtime representation with the current state.
  ///
  /// - Assume that if the current state was reached naturally this rule would be triggered
  /// as either a start or an update.
  /// - Throw an ``InvalidSyncFailure`` if this assumption fails.
  /// - Start any side effects which would be started when reaching this rule naturally.
  /// - Cancel active side effects invalidated by the new state.
  /// - The current state may not change during this sync.
  mutating func syncRuntime(with: RuleContext) throws
}

// MARK: - InvalidSyncFailure

struct InvalidSyncFailure: Error { }
