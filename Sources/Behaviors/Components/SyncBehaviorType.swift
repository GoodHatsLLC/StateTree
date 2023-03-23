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
    manager: BehaviorManager
  ) -> ScopedBehavior<Self> {
    .init(behavior: self, scope: scope, manager: manager)
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
