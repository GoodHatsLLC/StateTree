@_spi(Implementation) import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnStart

public struct OnStart<Behavior: BehaviorType>: Rules where Behavior.Input == Void {

  // MARK: Lifecycle

  @TreeActor
  public init(
    _ action: @TreeActor @escaping () -> Void
  ) where Behavior == Behaviors.SyncSingle<Void, Void, Never> {
    let behavior: Behaviors.SyncSingle<Behavior.Input, Void, Never> = Behaviors
      .make(input: Behavior.Input.self) { action() }
    self.behaviorMaker = { scope, manager in
      Surface(
        input: (),
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
  }

  @TreeActor
  public init(
    run behavior: Behavior
  )
    where Behavior: SyncBehaviorType
  {
    self.behaviorMaker = { scope, manager in
      Surface<Behavior>(
        input: (),
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
  }

  public init(
    run behavior: Behavior
  ) where Behavior: AsyncBehaviorType {
    self.behaviorMaker = { scope, manager in
      Surface<Behavior>(
        input: (),
        behavior: AttachableBehavior(behavior: behavior),
        scope: scope,
        manager: manager
      )
    }
  }

  public init(
    run behavior: Behavior
  ) where Behavior: StreamBehaviorType {
    self.behaviorMaker = { scope, manager in
      Surface<Behavior>(
        input: (),
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
    behaviorMaker(scope, context.runtime.behaviorManager)
      .fireAndForget()
  }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from _: Self,
    with _: RuleContext
  ) throws { }

  // MARK: Internal

  let behaviorMaker: (any BehaviorScoping, BehaviorManager) -> Surface<Behavior>
  let scope: BehaviorStage = .init()
}
