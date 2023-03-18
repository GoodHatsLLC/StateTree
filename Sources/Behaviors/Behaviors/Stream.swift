import Disposable
import TreeActor

// MARK: - Behaviors.Stream

extension Behaviors {
  public struct Stream<Input, Producer: AsyncSequence>: StreamBehaviorType {

    // MARK: Lifecycle

    public init(_ id: BehaviorID, subscriber: Behaviors.StreamSubscriber<Input, Producer>) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Value = Producer.Element
    public typealias Func = (_ input: Input) async -> Producer
    public typealias Subscriber = Behaviors.StreamSubscriber<Input, Producer>
    public typealias Resolution = Producer.Element
    public struct Handler: ThrowingStreamHandlerType {

      // MARK: Lifecycle

      public init(
        onValue: @escaping @TreeActor (Value) -> Void,
        onFinish: @escaping @TreeActor () -> Void,
        onFailure: @escaping @TreeActor (Error) -> Void,
        onCancel: @escaping @TreeActor () -> Void
      ) {
        self.onValue = onValue
        self.onFinish = onFinish
        self.onFailure = onFailure
        self.onCancel = onCancel
      }

      public init() {
        self.onValue = { _ in }
        self.onCancel = { }
        self.onFailure = { _ in }
        self.onFinish = { }
      }

      // MARK: Public

      public typealias Behavior = Stream<Input, Producer>
      public typealias Value = Producer.Element

      public func cancel() async {
        await onCancel()
      }

      // MARK: Internal

      let onValue: @TreeActor (_ value: Value) -> Void
      let onFinish: @TreeActor () -> Void
      let onFailure: @TreeActor (_ error: any Error) -> Void
      let onCancel: @TreeActor () -> Void

    }

    public let id: BehaviorID

    public let subscriber: Subscriber

    public func start(
      input: Input,
      handler: Handler,
      resolving resolution: Behaviors.Resolution
    ) async
      -> AnyDisposable
    {
      let producer = await subscriber.subscribe(input: input)
      let iterator = producer.makeAsyncIterator()
      let task = Task {
        do {
          var iterator = iterator
          while let iteration = try await iterator.next() {
            try Task.checkCancellation()
            await resolution.ifMatching { value in
              value == nil
            } run: {
              await handler.onValue(iteration)
            }
          }
          try Task.checkCancellation()
          await resolution.resolve(to: .finished) {
            await handler.onFinish()
          }
        } catch {
          try Task.checkCancellation()
          await resolution.resolve(to: .failed) {
            await handler.onFailure(error)
          }
        }
      }
      return AnyDisposable {
        task.cancel()
        Task {
          await resolution.resolve(to: .cancelled) {
            await handler.onCancel()
          }
        }
      }
    }
  }
}

extension Behaviors {
  public static func make<Input, Seq: AsyncSequence>(
    _ id: BehaviorID,
    _ maker: @escaping (_ input: Input) async -> Seq
  ) -> Behaviors.Stream<Input, Seq> {
    .init(id, subscriber: .init(maker))
  }
}
