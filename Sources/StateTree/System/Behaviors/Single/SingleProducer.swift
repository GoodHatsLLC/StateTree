
// MARK: - Behaviors.Producer

extension Behaviors {
  public struct SingleProducer<Input, Event: BehaviorEventType>: BehaviorProducerType {

    // MARK: Lifecycle

    public init(
      _ producer: @escaping @Sendable (
        _ input: Input,
        _ handler: Handler
      ) async -> Void
    ) {
      self.producerFunc = producer
    }

    // MARK: Public

    public typealias Input = Input
    public typealias Event = Event
    public typealias Handler = Behaviors.Handler<Event>

    @TreeActor
    public func start(input: Input, handler: Handler) -> AnyDisposable
      where Handler.Event == Event
    {
      Task {
        await withTaskCancellationHandler {
          await producerFunc(input, handler)
        } onCancel: {
          Task { @TreeActor in
            handler.send(event: .cancelledEvent)
          }
        }
      }
      .erase()
    }

    // MARK: Private

    private let producerFunc: @Sendable (
      _ input: Input,
      _ handler: Handler
    ) async -> Void
  }

}
