import Disposable
import TreeActor
import Utilities

// MARK: - Behaviors.SyncSingle

extension Behaviors {
  public struct SyncSingle<Input, Output, Failure: Error> {

    // MARK: Lifecycle

    public init(
      _ id: BehaviorID,
      subscribeFunc: @escaping Behaviors.Make<Input, Output>.SyncFunc.NonThrowing
    ) where Failure == Never {
      self.id = id
      self.subscriber = .init { input in .always { subscribeFunc(input) } }
    }

    public init(
      _ id: BehaviorID,
      subscribeFunc: @escaping Behaviors.Make<Input, Output>.SyncFunc.Throwing
    ) where Failure == Error {
      self.id = id
      self.subscriber = .init { input in .throwing { try subscribeFunc(input) } }
    }

    // MARK: Public

    public typealias Input = Input
    public typealias Output = Output
    public typealias Failure = Failure

    public typealias Producer = SyncOne<Output, Failure>
    public typealias Subscriber = Behaviors.SyncSubscriber<Input, Output, Failure>
    public typealias Handler = SyncHandler<Output, Failure>

    public let id: BehaviorID
    public let subscriber: Subscriber
  }
}

// MARK: - Behaviors.SyncSingle + SyncBehaviorType

extension Behaviors.SyncSingle: SyncBehaviorType {

  // MARK: Lifecycle

  @_spi(Implementation)
  public init(
    _ id: BehaviorID,
    subscriber: Behaviors.SyncSubscriber<Input, Output, Failure>
  ) {
    self.id = id
    self.subscriber = subscriber
  }

  // MARK: Public

  @TreeActor
  public func start(
    input: Input,
    handler: Behaviors.SyncHandler<Output, Failure>
  )
    -> Behaviors.Resolved
  {
    let producer = subscriber.subscribe(input: input)
    do {
      let out = try producer.resolve()
      handler.onResult(.success(out))
      return .init(id: id, state: .finished)
    } catch let error as Failure {
      handler.onResult(.failure(error))
      return .init(id: id, state: .failed)
    } catch {
      return .init(id: id, state: .failed)
    }
  }

}

extension Behaviors.SyncSingle where Failure == Error {

  @TreeActor
  func start(input: Input, handler: Behaviors.SyncHandler<Output, Failure>) -> Behaviors
    .Resolved
  {
    let producer = subscriber.subscribe(input: input)
    do {
      let out = try producer.resolve()
      handler.onResult(.success(out))
      return .init(id: id, state: .finished)
    } catch {
      handler.onResult(.failure(error))
      return .init(id: id, state: .failed)
    }
  }
}

extension Behaviors.SyncSingle where Failure == Never {

  @TreeActor
  func start(input: Input, handler: Behaviors.SyncHandler<Output, Failure>) -> Behaviors
    .Resolved
  {
    let output = subscriber.subscribe(input: input)
    handler.onResult(.success(output.resolve()))
    return .init(id: id, state: .finished)
  }
}

// MARK: - Behaviors.SyncHandler

extension Behaviors {

  public struct SyncHandler<Output, Failure: Error>: HandlerType {
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

    let onResult: @TreeActor (_ result: Result<Output, Failure>) -> Void
    let onCancel: @TreeActor () -> Void

  }
}

// MARK: - Behaviors.SyncHandler + ThrowingSingleHandlerType

extension Behaviors.SyncHandler: ThrowingSingleHandlerType where Failure == any Error {

  public init(
    onResult: @escaping @TreeActor (_ result: Result<Output, Error>) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  ) {
    self.init(result: onResult, cancel: onCancel)
  }
}

// MARK: - Behaviors.SyncHandler + SingleHandlerType

extension Behaviors.SyncHandler: SingleHandlerType where Failure == Never {

  public init(
    onSuccess: @escaping @TreeActor (_ value: Output) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  ) {
    self.init(
      result: { result in
        switch result {
        case .success(let value):
          onSuccess(value)
        }
      },
      cancel: onCancel
    )
  }
}
