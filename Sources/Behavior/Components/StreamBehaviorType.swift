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

// MARK: StreamBehaviorType.Func

extension StreamBehaviorType {
  typealias Func = (_ input: Input) async -> Producer
}
