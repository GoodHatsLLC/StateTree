import Disposable
import TreeActor

// MARK: - Behaviors.Async.Throwing.Stream

extension Behaviors.Async.Throwing {
  public struct Stream<Input, Value>: BehaviorType {

    // MARK: Lifecycle

    public init(_ id: BehaviorID, subscriber: Behaviors.Subscriber<Input, Producer>) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Resolution = Producer.Resolution

    public typealias Subscriber = Behaviors.Subscriber<Input, Producer>

    public typealias Input = Input
    public typealias Producer = ThrowingIteratorOf<Value>
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

      public typealias Behavior = Stream<Input, Value>
      public typealias Producer = ThrowingIteratorOf<Value>

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
      let task = Task {
        do {
          var maybeIteration = try await producer.first()
          while let iteration = maybeIteration {
            try Task.checkCancellation()
            await resolution.ifMatching { value in
              value == nil
            } run: {
              await handler.onValue(iteration.value)
            }
            maybeIteration = try await iteration.resolve()
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
    _ maker: @escaping (_ input: Input) throws -> Seq
  ) -> Async.Throwing.Stream<Input, Seq.Element> {
    .init(id, subscriber: .init { (input: Input) -> ThrowingIteratorOf<Seq.Element> in
      var iterator: Seq.AsyncIterator?
      var subscribeError: (any Error)?
      do {
        iterator = try maker(input).makeAsyncIterator()
        subscribeError = nil
      } catch {
        iterator = nil
        subscribeError = error
      }
      func makeNext() async throws -> ThrowingIterationOf<Seq.Element>? {
        if let subscribeError {
          throw subscribeError
        }
        guard let value = try await iterator?.next()
        else {
          return nil
        }
        return ThrowingIterationOf(value: value, makeNext)
      }
      return ThrowingIteratorOf(resolveFunc: makeNext)
    })
  }
}

// MARK: - SubscribeError

struct SubscribeError: Error { }
