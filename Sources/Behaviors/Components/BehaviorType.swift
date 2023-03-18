import Disposable
import TreeActor

// MARK: - BehaviorType

public protocol BehaviorType<Input, Value> {
  associatedtype Input
  associatedtype Value
  associatedtype Func
  associatedtype Producer
  associatedtype Resolution
  associatedtype Subscriber: SubscriberType where Subscriber.Input == Input
  associatedtype Handler: HandlerType where Handler.Value == Value
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

// MARK: - SingleBehaviorType

public protocol SingleBehaviorType<Input, Value>: BehaviorType
  where Func == (_ input: Input) async -> Value { }

// MARK: - SingleThrowingBehaviorType

public protocol SingleThrowingBehaviorType<Input, Value>: BehaviorType
  where Func == (_ input: Input) async throws -> Value { }

// MARK: - StreamBehaviorType

@rethrows
public protocol StreamBehaviorType<Input, Producer>: BehaviorType
  where Producer: AsyncSequence, Producer.Element == Value,
  Subscriber == Behaviors.StreamSubscriber<
    Input,
    Producer
  >, Func == (_ input: Input) async -> Producer
{ }
