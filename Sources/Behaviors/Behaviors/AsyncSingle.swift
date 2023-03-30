import Disposable
import TreeActor
import Utilities

// MARK: - Behaviors.AsyncSingle

extension Behaviors {
  public struct AsyncSingle<Input, Output, Failure: Error>: AsyncBehaviorType {

    // MARK: Lifecycle

    public init(
      _ id: BehaviorID,
      subscribeFunc: @escaping Behaviors.Make<Input, Output>.AsyncFunc.NonThrowing
    ) where Failure == Never {
      self.id = id
      self.subscriber = .init { await subscribeFunc($0) }
    }

    public init(
      _ id: BehaviorID,
      subscribeFunc: @escaping Behaviors.Make<Input, Output>.AsyncFunc.Throwing
    ) where Failure == Error {
      self.id = id
      self.subscriber = .init { try await subscribeFunc($0) }
    }

    @_spi(Implementation)
    public init(
      _ id: BehaviorID,
      subscriber: Behaviors.AsyncSubscriber<Input, Output, Failure>
    ) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Input = Input
    public typealias Output = Output
    public typealias Failure = Failure

    public typealias Producer = AsyncOne<Output, Failure>
    public typealias Subscriber = Behaviors.AsyncSubscriber<Input, Output, Failure>
    public typealias Handler = SingleHandler<Output, Failure>

    public let id: BehaviorID
    public let subscriber: Subscriber
  }
}

extension Behaviors.AsyncSingle where Failure: Error {

  // MARK: Public

  public func start(
    input: Input,
    handler: Handler,
    resolving resolution: Behaviors.Resolution
  ) async
    -> AnyDisposable
  {
    let producer = await subscriber.subscribe(input: input)
    return Disposables.Task.detached {
      try Task.checkCancellation()
      do {
        let value = try await producer.resolve()
        try Task.checkCancellation()
        await resolution.resolve(to: .finished) {
          await handler.onResult(.success(value))
        }
      } catch let error as Failure {
        await resolution.resolve(to: .failed) {
          await handler.onResult(.failure(error))
        }
      }
    } onDispose: {
      Task.detached {
        await resolution.resolve(to: .cancelled) {
          await handler.onCancel()
        }
      }
    }.erase()
  }

  // MARK: Internal

  typealias Func = Behaviors.Make<Input, Output>.AsyncFunc.NonThrowing

}

extension Behaviors.AsyncSingle where Failure == Never {

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
      let value = await producer.resolve()
      try Task.checkCancellation()
      await resolution.resolve(to: .finished) {
        await handler.onResult(.success(value))
      }
    }
    return AnyDisposable {
      task.cancel()
      Task.detached {
        await resolution.resolve(to: .cancelled) {
          await handler.onCancel()
        }
      }
    }
  }
}

// MARK: - Behaviors.SingleHandler + ThrowingSingleHandlerType

extension Behaviors.SingleHandler: ThrowingSingleHandlerType where Failure == any Error {
  public init(
    onResult: @escaping @TreeActor (_ result: Result<Output, Error>) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  ) {
    self.init(result: onResult, cancel: onCancel)
  }
}

// MARK: - Behaviors.SingleHandler + SingleHandlerType

extension Behaviors.SingleHandler: SingleHandlerType where Failure == Never {

  public init(
    onSuccess: @escaping @TreeActor (_ value: Output) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  ) {
    self.init(result: {
      switch $0 {
      case .success(let value):
        onSuccess(value)
      }
    }, cancel: onCancel)
  }
}

// MARK: - Behaviors.SingleHandler

extension Behaviors {
  public struct SingleHandler<Output, Failure: Error>: HandlerType {

    // MARK: Lifecycle

    init(
      result: @escaping @TreeActor (_ result: Result<Output, Failure>) -> Void,
      cancel: @escaping @TreeActor () -> Void
    ) {
      self.onResult = result
      self.onCancel = cancel
    }

    public init() {
      self.onCancel = { }
      self.onResult = { _ in }
    }

    @TreeActor
    public func cancel() {
      onCancel()
    }

    // MARK: Internal

    let onResult: @TreeActor (_ value: Result<Output, Failure>) -> Void
    let onCancel: @TreeActor () -> Void

  }
}
