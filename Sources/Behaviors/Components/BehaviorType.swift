import Disposable
import TreeActor

// MARK: - BehaviorType

public protocol BehaviorType<Input, Output, Failure> {
  associatedtype Input
  associatedtype Output
  associatedtype Failure: Error
  associatedtype Func
  associatedtype Producer
  associatedtype Subscriber: SubscriberType where Subscriber.Input == Input
  associatedtype Handler: HandlerType where Handler.Output == Output
  init(
    _ id: BehaviorID,
    subscriber: Subscriber
  )
  func start(
    input: Input,
    handler: Handler,
    resolving: Behaviors.Resolution
  ) async
    -> AnyDisposable
  var id: BehaviorID { get }
  var subscriber: Subscriber { get }
}

extension BehaviorType {
  public func scoped(
    to scope: some BehaviorScoping,
    manager: BehaviorManager
  ) -> ScopedBehavior<Self> {
    .init(behavior: .init(behavior: self), scope: scope, manager: manager)
  }
}

// MARK: BehaviorType.Func

extension BehaviorType where Failure == Never {
  public typealias Func = (_ input: Input) async -> Output
}

// MARK: BehaviorType.Func

extension BehaviorType where Failure == (any Error) {
  public typealias Func = (_ input: Input) async throws -> Output
}

// MARK: - StreamBehaviorType

@rethrows
public protocol StreamBehaviorType<Input, Output>: BehaviorType
  where Producer: AsyncSequence, Producer.Element == Output,
  Subscriber == Behaviors.StreamSubscriber<
    Input,
    Producer
  >, Func == (_ input: Input) async -> Producer
{ }

// MARK: - Make

public enum Make<Input, Output> { }
