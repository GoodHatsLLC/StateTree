import Disposable
import TreeActor

extension Behaviors.Async {
  public struct Stream<Input, Value>: BehaviorType {

    // MARK: Lifecycle

    public init(_ id: BehaviorID, subscriber: Behaviors.Subscriber<Input, Producer>) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Input = Input
    public typealias Producer = AlwaysIteratorOf<Value>
    public typealias Resolution = Producer.Resolution
    public typealias Subscriber = Behaviors.Subscriber<Input, Producer>
    public struct Handler: StreamHandlerType {
      public init(
        onValue: @escaping @TreeActor (Value) -> Void,
        onFinish: @escaping @TreeActor () -> Void,
        onCancel: @escaping @TreeActor () -> Void
      ) {
        self.onValue = onValue
        self.onFinish = onFinish
        self.onCancel = onCancel
      }

      public typealias Behavior = Stream<Input, Value>
      public init() {
        self.onCancel = { }
        self.onFinish = { }
        self.onValue = { _ in }
      }

      public typealias Producer = AlwaysIteratorOf<Value>
      let onValue: @TreeActor (_ value: Value) -> Void
      let onFinish: @TreeActor () -> Void
      let onCancel: @TreeActor () -> Void

      public func cancel() async {
        await onCancel()
      }
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
      let task = Task {
        var maybeIteration = await producer.first()
        while let iteration = maybeIteration {
          await resolution.ifMatching {
            $0 == nil
          } run: {
            if !Task.isCancelled {
              await handler.onValue(iteration.value)
            }
          }
          maybeIteration = await iteration.resolve()
        }
        await resolution.resolve(to: .finished) {
          await handler.onFinish()
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
