import Disposable
import TreeActor

// MARK: - SyncBehaviorType

public protocol SyncBehaviorType<Input, Output, Failure>: BehaviorType {
  var subscriber: Behaviors.SyncSubscriber<Input, Output, Failure> { get }
  func start(input: Input, handler: Handler, resolving: Behaviors.Resolution) -> AutoDisposable
}

extension SyncBehaviorType {

  @TreeActor
  public func scoped(
    to scope: some BehaviorScoping,
    tracker: BehaviorTracker,
    input: Input
  ) -> ScopedBehavior<Self> {
    .init(behavior: self, scope: scope, tracker: tracker, input: input)
  }

  @TreeActor
  public func scoped(
    to scope: some BehaviorScoping,
    tracker: BehaviorTracker
  ) -> ScopedBehavior<Self> where Input == Void {
    .init(behavior: self, scope: scope, tracker: tracker, input: ())
  }

  @TreeActor
  public func scoped(
    tracker: BehaviorTracker,
    input: Input
  ) -> (scope: some Disposable, behavior: ScopedBehavior<Self>) {
    let stage = BehaviorStage()
    return (stage, .init(behavior: self, scope: stage, tracker: tracker, input: input))
  }

  @TreeActor
  public func scoped(tracker: BehaviorTracker)
    -> (scope: some Disposable, behavior: ScopedBehavior<Self>) where Input == Void
  {
    let stage = BehaviorStage()
    return (stage, .init(behavior: self, scope: stage, tracker: tracker, input: ()))
  }
}

// MARK: SyncBehaviorType.Func

extension SyncBehaviorType where Failure == Never {
  typealias Func = (_ input: Input) -> Output
}

// MARK: SyncBehaviorType.Func

extension SyncBehaviorType where Failure == Error {
  typealias Func = (_ input: Input) throws -> Output
}
