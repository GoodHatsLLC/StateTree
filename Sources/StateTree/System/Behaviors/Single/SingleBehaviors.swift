import Emitter
import Foundation

extension Behavior where Failure == Never, Output == Never {

  public static func single(
    id: BehaviorID,
    eventProducer: @escaping SingleProducerFunc
  ) -> Behaviors.AlwaysSingle<
    Input,
    Success
  > {
    let producerArg: @Sendable (
      Input, Behaviors.Handler<SingleEvent>
    ) async
      -> Void = { input, handler in
        await eventProducer(input, handler.sender)
      }

    return .init(id: id, producer: Behaviors.SingleProducer<Input, SingleEvent>(producerArg))
  }
}

extension Behavior where Failure: Error, Output == Never {
  public static func failableSingle(
    id: BehaviorID,
    eventProducer: @escaping ThrowingSingleProducer
  ) -> Behaviors.FailableSingle<
    Input,
    Success
  > {
    let producerArg: @Sendable (
      Input, Behaviors.Handler<ThrowingSingleEvent>
    ) async
      -> Void = { input, handler in
        await eventProducer(input, handler.sender)
      }

    return .init(id: id, producer: Behaviors.SingleProducer(producerArg))
  }
}

// MARK: - Behaviors.Single

extension Behaviors {

  // MARK: - Single

  public struct Single<
    Input,
    Success: Sendable,
    Failure: Error
  >: BehaviorType {

    // MARK: Lifecycle

    public init(
      id: BehaviorID,
      producer: Producer
    ) {
      self.id = id
      self.producer = producer
    }

    // MARK: Public

    public typealias Input = Input
    public typealias State = SingleBehaviorState<Success, Failure>
    public typealias Event = BehaviorEvents.Single<Success, Failure>
    public typealias Producer = Behaviors.SingleProducer<
      Input,
      BehaviorEvents.Single<Success, Failure>
    >
    public let id: BehaviorID
    public let producer: Behaviors
      .SingleProducer<Input, BehaviorEvents.Single<Success, Failure>>
  }
}

// MARK: - Behaviors.Single.Event

extension Behaviors.Single where Success == Never {
  public typealias Event = BehaviorEvents.Single<Never, Failure>
}
