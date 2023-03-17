import Disposable
import TreeActor

// MARK: - Behaviors.Single

extension Behaviors {
  public struct Single<Input, Value>: BehaviorType {

    // MARK: Lifecycle

    public init(_ id: BehaviorID, subscriber: Subscriber) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Value = Value
    public typealias Resolution = Producer.Resolution
    public typealias Subscriber = Behaviors.Subscriber<Input, Producer>

    public typealias Input = Input
    public typealias Producer = OnlyOne<Immediate<Value>>
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
      public typealias Producer = OnlyOne<Immediate<Value>>

      public func cancel() async {
        await onCancel()
      }

      // MARK: Internal

      let onSuccess: @TreeActor (_ value: Value) -> Void
      let onCancel: @TreeActor () -> Void

      func handle(_ event: Immediate<Value>) -> AnyDisposable {
        AnyDisposable(
          Task { @TreeActor in
            let event = event.resolve()
            onSuccess(event)
          }
        )
      }

    }

    public let id: BehaviorID

    public let subscriber: Behaviors.Subscriber<Input, Producer>

    public func start(
      input: Input,
      handler: Handler,
      resolving resolution: Behaviors.Resolution
    ) async
      -> AnyDisposable
    {
      let producer = await subscriber.subscribe(input: input)
      let task = Task { @TreeActor in
        if Task.isCancelled {
          return
        }
        let value = producer.value.resolve()
        await resolution.resolve(to: .finished) {
          if !Task.isCancelled {
            handler.onSuccess(value)
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
  public static func make<Input, Value>(
    _ id: BehaviorID,
    _ maker: @escaping (_ input: Input) -> Value
  ) -> Single<Input, Value> {
    .init(id, subscriber: .init { (input: Input) in
      OnlyOne(value: .init {
        maker(input)
      })
    })
  }
}
