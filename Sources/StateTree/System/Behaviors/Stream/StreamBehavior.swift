import Emitter
import Foundation

extension Behavior {

  public typealias StreamSendFunc = @Sendable @TreeActor (StreamEvent) -> Void

  public typealias StreamProducerFunc = @Sendable (
    _ input: Input,
    _ send: @escaping StreamSendFunc
  ) throws -> Void
}

extension Behavior {

  public static func stream(
    id: BehaviorID,
    eventProducer: @escaping StreamProducerFunc
  ) -> Behaviors.Stream<
    Input,
    Output,
    Failure
  > {
    let producerArg: Behaviors.StreamProducer<Input, StreamEvent>.HandlerFunc = { input, handler in
      try eventProducer(input, handler.sender)
    }

    return .init(id: id, producer: Behaviors.StreamProducer<Input, StreamEvent>(producerArg))
  }
}

extension Behavior where Failure == Error, Success == Never, Output: Any {

  public static func stream(
    id: BehaviorID,
    eventProducer: @escaping StreamProducerFunc
  ) -> Behaviors.Stream<
    Input,
    Output,
    Failure
  > {
    typealias HandlerFunc = Behaviors.StreamProducer<Input, StreamEvent>.HandlerFunc
    let producerArg: HandlerFunc = { input, handler in
      do {
        try eventProducer(input, handler.sender)
      } catch {
        handler.send(event: .failed(error))
      }
    }
    return .init(id: id, producer: Behaviors.StreamProducer(producerArg))
  }
}

// MARK: - Behaviors.Stream

extension Behaviors {

  // MARK: - Single

  public struct Stream<
    Input,
    Output: Sendable,
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
    public typealias State = StreamBehaviorState<Output, Failure>
    public typealias Event = BehaviorEvents.Stream<Output>
    public typealias Producer = Behaviors.StreamProducer<Input, BehaviorEvents.Stream<Output>>
    public let id: BehaviorID
    public let producer: Behaviors
      .StreamProducer<Input, BehaviorEvents.Stream<Output>>
  }
}
