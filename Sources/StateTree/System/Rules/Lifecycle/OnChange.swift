@_spi(Implementation) import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnChange

public struct OnChange<Behavior: BehaviorType>: Rules where Behavior.Input: Equatable {

  // MARK: Lifecycle

  @TreeActor
  public init<Value: Equatable>(
    _ input: Value,
    _ action: @TreeActor @escaping (_ value: Behavior.Input) -> Void
  ) where Behavior == Behaviors.SyncSingle<Value, Void, Never> {
    self.value = input
    let behavior: Behaviors.SyncSingle<Behavior.Input, Void, Never> = Behaviors
      .make(input: Behavior.Input.self) { action($0) }
    self.behaviorMaker = { input, scope, manager in
      Surface(
        input: input,
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
  }

  public init<Value: Equatable>(
    _ input: Value,
    _ action: @TreeActor @escaping (_ value: Behavior.Input) async -> Void
  ) where Behavior == Behaviors.AsyncSingle<Value, Void, Never> {
    self.value = input
    let behavior: Behaviors.AsyncSingle<Behavior.Input, Void, Never> = Behaviors
      .make(input: Behavior.Input.self) { await action($0) }
    self.behaviorMaker = { input, scope, manager in
      Surface(
        input: input,
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
  }

  @TreeActor
  public init(
    _ input: Behavior.Input,
    run behavior: Behavior
  )
    where Behavior: SyncBehaviorType
  {
    self.value = input
    self.behaviorMaker = { input, scope, manager in
      Surface<Behavior>(
        input: input,
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
  }

  public init(
    _ input: Behavior.Input,
    run behavior: Behavior
  ) where Behavior: AsyncBehaviorType {
    self.value = input
    self.behaviorMaker = { input, scope, manager in
      Surface<Behavior>(
        input: input,
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
  }

  public init(
    _ input: Behavior.Input,
    run behavior: Behavior
  ) where Behavior: StreamBehaviorType {
    self.value = input
    self.behaviorMaker = { input, scope, manager in
      Surface<Behavior>(
        input: input,
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
  }

  // MARK: Public

  public func act(
    for _: RuleLifecycle,
    with _: RuleContext
  )
    -> LifecycleResult
  {
    .init()
  }

  public mutating func applyRule(with context: RuleContext) throws {
    behaviorMaker(value, scope, context.runtime.behaviorManager)
      .fireAndForget()
  }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from newRule: Self,
    with context: RuleContext
  ) throws {
    if value != newRule.value {
      value = newRule.value
      scope.reset()
      behaviorMaker(value, scope, context.runtime.behaviorManager)
        .fireAndForget()
    }
  }

  // MARK: Internal

  let behaviorMaker: (Behavior.Input, any BehaviorScoping, BehaviorManager) -> Surface<Behavior>
  let scope: BehaviorStage = .init()
  var value: Behavior.Input
}
