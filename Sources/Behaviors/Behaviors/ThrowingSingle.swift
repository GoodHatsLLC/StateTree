import Disposable
import TreeActor

// MARK: - Behaviors.Sync.Throwing.Single

extension Behaviors.Sync.Throwing {
  public struct Single<Input, Value>: BehaviorType {

    // MARK: Lifecycle

    public init(_ id: BehaviorID, subscriber: Subscriber) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Input = Input
    public typealias Value = Value
    public typealias Resolution = Producer.Resolution
    public typealias Subscriber = Behaviors.Subscriber<Input, Producer>
    public typealias Producer = OnlyOne<EventualThrowing<Value>>
    public struct Handler: ThrowingSingleHandlerType {
      public init(
        onResult: @escaping @TreeActor (Result<Value, Error>) -> Void,
        onCancel: @escaping @TreeActor () -> Void
      ) {
        self.onResult = onResult
        self.onCancel = onCancel
      }

      public typealias Behavior = Single<Input, Value>
      public init() {
        self.onCancel = { }
        self.onResult = { _ in }
      }

      public typealias Producer = OnlyOne<EventualThrowing<Value>>
      let onResult: @TreeActor (_ result: Result<Value, Error>) -> Void
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
        do {
          let result = try await producer.value.resolve()
          await resolution.resolve(to: .finished) {
            if !Task.isCancelled {
              await handler.onResult(.success(result))
            }
          }
        } catch {
          await resolution.resolve(to: .failed) {
            if !Task.isCancelled {
              await handler.onResult(.failure(error))
            }
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
  public static func make<Input, Value>(
    _ id: BehaviorID,
    _ maker: @escaping (_ input: Input) throws -> Value
  ) -> Sync.Throwing.Single<Input, Value> {
    .init(id, subscriber: .init { (input: Input) in
      OnlyOne(value: .init {
        try maker(input)
      })
    })
  }
}
