import Disposable
import TreeActor

// MARK: - AsyncBehaviorType

public protocol AsyncBehaviorType<Input, Output, Failure>: BehaviorType {
  func start(
    input: Input,
    handler: Handler,
    resolving: Behaviors.Resolution
  ) async
    -> AutoDisposable

  var subscriber: Behaviors.AsyncSubscriber<Input, Output, Failure> { get }
}

/// TODO: remove
extension AsyncBehaviorType {

  // MARK: Public

  public func scoped(
    to scope: some BehaviorScoping,
    tracker: BehaviorTracker
  ) -> ScopedBehavior<Self> where Input == Void {
    .init(behavior: self, scope: scope, tracker: tracker, input: ())
  }

  // MARK: Internal

  func scoped(
    to scope: some BehaviorScoping,
    tracker: BehaviorTracker,
    input: Input
  ) -> ScopedBehavior<Self> {
    .init(behavior: self, scope: scope, tracker: tracker, input: input)
  }

  func scoped(
    tracker: BehaviorTracker,
    input: Input
  ) -> (scope: some Disposable, behavior: ScopedBehavior<Self>) {
    let stage = BehaviorStage()
    return (stage, .init(behavior: self, scope: stage, tracker: tracker, input: input))
  }

  func scoped(tracker: BehaviorTracker)
    -> (scope: some Disposable, behavior: ScopedBehavior<Self>) where Input == Void
  {
    let stage = BehaviorStage()
    return (stage, .init(behavior: self, scope: stage, tracker: tracker, input: ()))
  }
}

// MARK: AsyncBehaviorType.Func

extension AsyncBehaviorType where Failure == Never {
  typealias Func = (_ input: Input) async -> Output
}

// MARK: AsyncBehaviorType.Func

extension AsyncBehaviorType where Failure == Error {
  typealias Func = (_ input: Input) async throws -> Output
}
