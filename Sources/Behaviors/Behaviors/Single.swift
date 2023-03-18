import Disposable
import TreeActor

// MARK: - Behaviors.Single

extension Behaviors {
  public struct Single<Input, Value>: SingleBehaviorType {

    // MARK: Lifecycle

    public init(_ id: BehaviorID, subscriber: Behaviors.Subscriber<Input, Producer>) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Func = (Input) async -> Value
    public typealias Resolution = Producer.Resolution
    public typealias Producer = One<Eventual<Value>>
    public typealias Subscriber = Behaviors.Subscriber<Input, Producer>

    public struct Handler: SingleHandlerType {

      // MARK: Lifecycle

      public init(
        onSuccess: @escaping @TreeActor (Value) -> Void,
        onCancel: @escaping @TreeActor () -> Void
      ) {
        self.onSuccess = onSuccess
        self.onCancel = onCancel
      }

      public init() {
        self.onCancel = { }
        self.onSuccess = { _ in }
      }

      // MARK: Public

      public typealias Behavior = Single<Input, Value>
      public typealias Producer = One<Eventual<Value>>

      public func cancel() async {
        await onCancel()
      }

      // MARK: Internal

      let onSuccess: @TreeActor (_ value: Value) -> Void
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
      let task = Task {
        try Task.checkCancellation()
        let value = await producer.value.resolve()
        try Task.checkCancellation()
        await resolution.resolve(to: .finished) {
          await handler.onSuccess(value)
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
  public static func make<Input, T>(
    _ id: BehaviorID,
    _ maker: @escaping (_ input: Input) async -> T
  ) -> Single<Input, T> {
    .init(id, subscriber: .init { (input: Input) in
      One(value: .init {
        await maker(input)
      })
    })
  }
}
