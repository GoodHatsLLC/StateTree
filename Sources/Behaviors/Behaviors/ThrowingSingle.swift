import Disposable
import Emitter
import TreeActor

// MARK: - Behaviors.Throwing.Single

extension Behaviors.Throwing {
  public struct Single<Input, Value>: SingleThrowingBehaviorType {

    // MARK: Lifecycle

    public init(_ id: BehaviorID, subscriber: Subscriber) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Func = (Input) async throws -> Value
    public typealias Resolution = Producer.Resolution
    public typealias Subscriber = Behaviors.Subscriber<Input, Producer>
    public typealias Producer = One<EventualThrowing<Value>>
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

      public typealias Producer = One<EventualThrowing<Value>>
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
          let value = try await producer.value.resolve()
          await resolution.resolve(to: .finished) {
            await handler.onResult(.success(value))
          }
        } catch {
          await resolution.resolve(to: .failed) {
            await handler.onResult(.failure(error))
          }
        }
      }
      return AnyDisposable {
        Task {
          await resolution.resolve(to: .cancelled) {
            task.cancel()
            await handler.onCancel()
          }
        }
      }
    }
  }
}

extension Behaviors {
  public static func make<Input, T>(
    _ id: BehaviorID,
    _ maker: @escaping (_ input: Input) async throws -> T
  ) -> Throwing.Single<Input, T> {
    .init(id, subscriber: .init { (input: Input) in
      One(value: .init {
        try await maker(input)
      })
    })
  }
}
