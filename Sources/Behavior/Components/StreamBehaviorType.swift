import Disposable
import TreeActor

// MARK: - StreamBehaviorType

public protocol StreamBehaviorType<Input, Output, Failure>: BehaviorType
  where Producer: AsyncSequence, Producer.Element == Output
{
  var subscriber: Behaviors.StreamSubscriber<Input, Output, Failure> { get }
  func start(
    input: Input,
    handler: Handler,
    resolving: Behaviors.Resolution
  ) async
    -> AutoDisposable
}

/// TODO: remove
extension StreamBehaviorType {
  func scoped(
    to scope: some BehaviorScoping,
    tracker: BehaviorTracker,
    input: Input
  ) -> ScopedBehavior<Self> {
    .init(behavior: self, scope: scope, tracker: tracker, input: input)
  }

  func scoped(
    to scope: some BehaviorScoping,
    tracker: BehaviorTracker
  ) -> ScopedBehavior<Self> where Input == Void {
    .init(behavior: self, scope: scope, tracker: tracker, input: ())
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

// MARK: StreamBehaviorType.Func

extension StreamBehaviorType {
  typealias Func = (_ input: Input) async -> Producer
}
