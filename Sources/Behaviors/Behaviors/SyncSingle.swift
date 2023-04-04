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
    public typealias Handler = SingleHandler<Synchronous, Output, Failure>

    public let id: BehaviorID
    public let subscriber: Subscriber
  }
}

// MARK: - Behaviors.SyncSingle + BehaviorEffect

extension Behaviors.SyncSingle: BehaviorEffect where Failure == Handler.Failure {
  public var switchType: BehaviorEmissionType<Input, Output, Failure> {
    .sync(self)
  }

  public mutating func setID(to: BehaviorID) {
    self = .init(to, subscriber: subscriber)
  }

}

// MARK: - Behaviors.SyncSingle + BehaviorType

extension Behaviors.SyncSingle: BehaviorType where Failure == Handler.Failure {
  public init(_ id: BehaviorID, subscriber: Behaviors.SyncSubscriber<Input, Output, Failure>) {
    self.id = id
    self.subscriber = subscriber
  }
}

// MARK: - Behaviors.SyncSingle + SyncBehaviorType

extension Behaviors.SyncSingle: SyncBehaviorType where Failure == Handler.Failure {

  @TreeActor
  public func start(
    input: Input,
    handler: Behaviors.SingleHandler<Synchronous, Output, Failure>
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
  func start(
    input: Input,
    handler: Behaviors.SingleHandler<Synchronous, Output, Failure>
  )
    -> Behaviors
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
  func start(
    input: Input,
    handler: Behaviors.SingleHandler<Synchronous, Output, Failure>
  )
    -> Behaviors
    .Resolved
  {
    let output = subscriber.subscribe(input: input)
    handler.onResult(.success(output.resolve()))
    return .init(id: id, state: .finished)
  }
}

// MARK: - BehaviorSubscribeType

public protocol BehaviorSubscribeType { }

// MARK: - Synchronous

public enum Synchronous: BehaviorSubscribeType { }

// MARK: - Asynchronous

public enum Asynchronous: BehaviorSubscribeType { }

// MARK: - Behaviors.SingleHandler

extension Behaviors {

  public struct SingleHandler<
    SubscribeType: BehaviorSubscribeType,
    Output,
    Failure: Error
  >: SingleHandlerType {
    public init(
      onResult: @escaping @TreeActor (_ result: Result<Output, Failure>) -> Void,
      onCancel: @escaping @TreeActor () -> Void
    ) {
      self.onResult = onResult
      self.onCancel = onCancel
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
