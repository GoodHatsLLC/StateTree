import Disposable
import TreeActor

// MARK: - SyncBehaviorType

public protocol SyncBehaviorType<Input, Output, Failure>: BehaviorType
  where Handler == Behaviors.SyncHandler<Output, Failure>
{
  var subscriber: Behaviors.SyncSubscriber<Input, SyncOne<Output, Failure>> { get }

  func start(input: Input, handler: Behaviors.SyncHandler<Output, Failure>) -> Behaviors
    .Resolved
}

extension SyncBehaviorType {

  @TreeActor
  public func scoped(
    to scope: some BehaviorScoping,
    manager: BehaviorManager,
    input: Input
  ) -> ScopedBehavior<Self> {
    .init(behavior: self, scope: scope, manager: manager, input: input)
  }

  @TreeActor
  public func scoped(
    to scope: some BehaviorScoping,
    manager: BehaviorManager
  ) -> ScopedBehavior<Self> where Input == Void {
    .init(behavior: self, scope: scope, manager: manager, input: ())
  }

  @TreeActor
  public func scoped(
    manager: BehaviorManager,
    input: Input
  ) -> (scope: some Disposable, behavior: ScopedBehavior<Self>) {
    let stage = BehaviorStage()
    return (stage, .init(behavior: self, scope: stage, manager: manager, input: input))
  }

  @TreeActor
  public func scoped(manager: BehaviorManager)
    -> (scope: some Disposable, behavior: ScopedBehavior<Self>) where Input == Void
  {
    let stage = BehaviorStage()
    return (stage, .init(behavior: self, scope: stage, manager: manager, input: ()))
  }
}

// MARK: SyncBehaviorType.Func

extension SyncBehaviorType where Failure == Never {
  public typealias Func = (_ input: Input) -> Output
}

// MARK: SyncBehaviorType.Func

extension SyncBehaviorType where Failure == Error {
  public typealias Func = (_ input: Input) throws -> Output
}
