import Disposable
import TreeActor
import Utilities

// MARK: - Behaviors.AsyncSingle

extension Behaviors {
  public struct AsyncSingle<Input, Output, Failure: Error>: AsyncBehaviorType {

    // MARK: Lifecycle

    public init(_ id: BehaviorID, subscriber: Behaviors.AsyncSubscriber<Input, Producer>) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Input = Input
    public typealias Output = Output
    public typealias Failure = Failure

    public typealias Producer = AsyncOne<Output, Failure>
    public typealias Subscriber = Behaviors.AsyncSubscriber<Input, Producer>
    public typealias Handler = SingleHandler<Output, Failure>
    public let id: BehaviorID

    public let subscriber: Subscriber
  }
}

extension Behaviors.AsyncSingle where Failure: Error {
  public typealias Func = Behaviors.Make<Input, Output>.Func.NonThrowing

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
      Task {
        await resolution.resolve(to: .cancelled) {
          await handler.onCancel()
        }
      }
    }
  }
}

// MARK: - Behaviors.SingleHandler + HandlerType

extension Behaviors.SingleHandler: HandlerType { }

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

extension Behaviors {
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping Behaviors.Make<Input, Output>.Func.NonThrowing
  ) -> AsyncSingle<Input, Output, Never> {
    .init(
      id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "nt-single"),
      subscriber: .init { (input: Input) in
        AsyncOne.always {
          await subscribe(input)
        }
      }
    )
  }
}

extension Behaviors {
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping Behaviors.Make<Input, Output>.Func.Throwing
  ) -> AsyncSingle<Input, Output, any Error> {
    .init(
      id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "t-single"),
      subscriber: .init { (input: Input) in
        AsyncOne.throwing {
          try await subscribe(input)
        }
      }
    )
  }
}

// MARK: - Behaviors.SingleHandler

extension Behaviors {
  public struct SingleHandler<Output, Failure: Error> {

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
