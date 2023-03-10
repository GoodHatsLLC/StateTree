
// MARK: - Behaviors.Producer

extension Behaviors {

  public struct StreamProducer<Input, Event: BehaviorEventType>: BehaviorProducerType {

    // MARK: Lifecycle

    public init(
      _ producer: @escaping HandlerFunc
    ) {
      self.producerFunc = producer
    }

    // MARK: Public

    public typealias Input = Input
    public typealias Event = Event
    public typealias Handler = Behaviors.Handler<Event>
    public typealias HandlerFunc = @Sendable @TreeActor (
      _ input: Input,
      _ handler: Handler
    ) throws -> Void // TODO: remove throws

    @TreeActor
    public func start(input: Input, handler: Handler) -> AnyDisposable
      where Handler.Event == Event
    {
      do {
        try producerFunc(input, handler)
      } catch {
        handler.send(event: .cancelledEvent)
      }
      return AnyDisposable {
        handler.send(event: .cancelledEvent)
      }
    }

    // MARK: Private

    private let producerFunc: HandlerFunc
  }

}
