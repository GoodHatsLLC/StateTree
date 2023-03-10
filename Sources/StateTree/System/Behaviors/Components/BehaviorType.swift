import Disposable

// MARK: - Behaviors

public enum Behaviors {
  public typealias AlwaysSingle<Input, Value: Sendable> = Single<Input, Value, Never>
  public typealias FailableSingle<Input, Value: Sendable> = Single<Input, Value, Error>
}

// MARK: - BehaviorType

public protocol BehaviorType {
  associatedtype Input
  associatedtype Event: BehaviorEventType
  associatedtype State: BehaviorStateType where State.Event == Event
  associatedtype Producer: BehaviorProducerType where Producer.Event == Event,
    Producer.Input == Input
  associatedtype Handler: BehaviorHandlerType where Handler == Behaviors.Handler<Event>,
    Handler == Producer.Handler
  init(id: BehaviorID, producer: Producer)
  var id: BehaviorID { get }
  var producer: Producer { get }
}

// MARK: - BehaviorEventType

public protocol BehaviorEventType {
  associatedtype Output: Sendable
  associatedtype Success: Sendable
  associatedtype Failure: Error
  static var cancelledEvent: Self { get }
  var isCancellation: Bool { get }
}

// MARK: - BehaviorEvents

public enum BehaviorEvents { }

// MARK: - BehaviorCancellationError

public struct BehaviorCancellationError: Error { }

// MARK: - Behavior

public enum Behavior<Input, Output: Sendable, Success: Sendable, Failure: Error> {
  public typealias SingleEvent = BehaviorEvents.Single<Success, Never>
  public typealias SingleProducerFunc = @Sendable (
    _ input: Input,
    _ send: @Sendable @TreeActor (SingleEvent) -> Void
  ) async -> Void
  public typealias ThrowingSingleEvent = BehaviorEvents.Single<Success, Error>
  public typealias ThrowingSingleProducer = @Sendable (
    _ input: Input,
    _ send: @Sendable @TreeActor (ThrowingSingleEvent) -> Void
  ) async -> Void
  public typealias StreamEvent = BehaviorEvents.Stream<Output>

}
