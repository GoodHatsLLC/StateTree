@_spi(Implementation) import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - WithChange

public struct WithChange<Behavior: BehaviorType>: Rules where Behavior.Input: Equatable {

  // MARK: Lifecycle

  @TreeActor
  public init<Value>(
    _ input: Value,
    _ action: @TreeActor @escaping (_ value: Value) -> Void
  ) where Behavior == Behaviors.SyncSingle<Value, Value, Never> {
    self.value = input
    let behavior = Behaviors.make(input: Value.self) { $0 }
    self.surfaceMaker = { scope, manager in
      Surface<Behavior>(
        input: input,
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
    self.handler = { then in
      then.onSuccess { output in
        action(output)
      }
    }
  }

  @TreeActor
  public init(
    _ input: Behavior.Input,
    run behavior: Behavior,
    handler: @escaping (_ then: Surface<Behavior>) -> Void
  )
    where Behavior: SyncBehaviorType
  {
    self.value = input
    self.surfaceMaker = { scope, manager in
      Surface<Behavior>(
        input: input,
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
    self.handler = handler
  }

  public init(
    _ input: Behavior.Input,
    run behavior: Behavior,
    handler: @escaping (_ then: Surface<Behavior>) -> Void
  )
    where Behavior: AsyncBehaviorType
  {
    self.value = input
    self.surfaceMaker = { scope, manager in
      Surface<Behavior>(
        input: input,
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
    self.handler = handler
  }

  public init(
    _ input: Behavior.Input,
    run behavior: Behavior,
    handler: @escaping (_ then: Surface<Behavior>) -> Void
  )
    where Behavior: StreamBehaviorType
  {
    self.value = input
    self.surfaceMaker = { scope, manager in
      Surface<Behavior>(
        input: input,
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
    self.handler = handler
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

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from newRule: Self,
    with context: RuleContext
  ) throws {
    if value != newRule.value {
      value = newRule.value
      scope.reset()
      let surface = surfaceMaker(scope, context.runtime.behaviorManager)
      handler(surface)
    }
  }

  // MARK: Internal

  let surfaceMaker: (any BehaviorScoping, BehaviorManager) -> Surface<Behavior>
  let handler: (_ then: Surface<Behavior>) -> Void
  var value: Behavior.Input
  let scope: BehaviorStage = .init()
}

// MARK: - AfterChange

public struct AfterChange<Input: Equatable>: Rules {

  // MARK: Lifecycle

  public init<B: SyncBehaviorType>(_ input: Input, run behavior: B, with handler: B.Handler)
    where B.Input == Input
  {
    self.startable = StartableBehavior<Input>(behavior: behavior, handler: handler)
    self.value = input
  }

  public init<B: AsyncBehaviorType>(_ input: Input, run behavior: B, with handler: B.Handler)
    where B.Input == Input
  {
    self.startable = StartableBehavior<Input>(behavior: behavior, handler: handler)
    self.value = input
  }

  public init<B: StreamBehaviorType>(_ input: Input, run behavior: B, with handler: B.Handler)
    where B.Input == Input
  {
    self.startable = StartableBehavior<Input>(behavior: behavior, handler: handler)
    self.value = input
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

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from newRule: Self,
    with context: RuleContext
  ) throws {
    if value != newRule.value {
      value = newRule.value
      start(startable, input: value, context: context)
    }
  }

  // MARK: Internal

  let startable: StartableBehavior<Input>
  var value: Input

  // MARK: Private

  private func start(
    _ startable: StartableBehavior<Input>,
    input: Input,
    context: RuleContext
  ) {
    let (_, finalizer) = startable.start(
      manager: context.runtime.behaviorManager,
      input: input,
      scope: context.scope
    )
    if let finalizer {
      context.scope.own(
        Disposables.Task.detached {
          await finalizer()
        } onDispose: { }
      )
    }
  }

}
