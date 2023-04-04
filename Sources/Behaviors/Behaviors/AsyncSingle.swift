import Disposable
import TreeActor
import Utilities

// MARK: - Behaviors.AsyncSingle

extension Behaviors {
  public struct AsyncSingle<Input, Output, Failure: Error> {

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

    // MARK: Public

    public typealias Input = Input
    public typealias Output = Output
    public typealias Failure = Failure

    public typealias Producer = AsyncOne<Output, Failure>
    public typealias Subscriber = Behaviors.AsyncSubscriber<Input, Output, Failure>
    public typealias Handler = SingleHandler<Output, Failure>

    public let id: BehaviorID
    public let subscriber: Subscriber

    public var switchType: BehaviorEmissionType<Input, Output, Failure> {
      .async(self)
    }

  }
}

// MARK: - Behaviors.AsyncSingle + BehaviorEffect

extension Behaviors.AsyncSingle: BehaviorEffect where Failure == Handler.Failure { }

// MARK: - Behaviors.AsyncSingle + BehaviorType

extension Behaviors.AsyncSingle: BehaviorType where Failure == Handler.Failure {
  public init(_ id: BehaviorID, subscriber: Behaviors.AsyncSubscriber<Input, Output, Failure>) {
    self.id = id
    self.subscriber = subscriber
  }
}

// MARK: - Behaviors.AsyncSingle + AsyncBehaviorType

extension Behaviors.AsyncSingle: AsyncBehaviorType where Failure == Handler.Failure {

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
