import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - Behaviors.Stream

extension Behaviors {
  public struct Stream<Input, Output, Failure: Error> {

    // MARK: Lifecycle

    public init<Seq: AsyncSequence>(
      _ id: BehaviorID,
      subscribeFunc: @escaping Behaviors.Make<Input, Output>.StreamFunc.Concrete<Seq>
    ) where Output == Seq.Element {
      self.id = id
      self.subscriber = .init(subscribeFunc)
    }

    @_spi(Implementation)
    public init(
      _ id: BehaviorID,
      subscriber: Behaviors.StreamSubscriber<Input, Output, Failure>
    ) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Producer = AnyAsyncSequence<Output>
    public typealias Input = Input
    public typealias Output = Output
    public typealias Func = Behaviors.Make<Input, Output>.StreamFunc
    public typealias Handler = Behaviors.StreamHandler<Asynchronous, Output, Failure>
    public typealias Subscriber = Behaviors.StreamSubscriber<Input, Output, Failure>
    public typealias Resolution = Producer.Element

    public let id: BehaviorID

    public let subscriber: Subscriber

    public var switchType: BehaviorEmissionType<Input, Output, Failure> {
      .stream(self)
    }

    public func start(
      input: Input,
      handler: Handler,
      resolving resolution: Behaviors.Resolution
    ) async
      -> AutoDisposable
    {
      let producer = await subscriber.subscribe(input: input)
      let iterator = producer.makeAsyncIterator()
      let task = Task {
        do {
          while let iteration = try await iterator.next() {
            try Task.checkCancellation()
            await resolution.ifMatching { value in
              value == nil
            } run: {
              await handler.onValue(iteration)
            }
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
      return AutoDisposable {
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

// MARK: - Behaviors.Stream + StreamBehaviorType

extension Behaviors.Stream: StreamBehaviorType where Failure == Handler.Failure {
  public mutating func setID(to: BehaviorID) {
    self = .init(to, subscriber: subscriber)
  }
}

// MARK: - Behaviors.StreamHandler

extension Behaviors {
  public struct StreamHandler<
    SubscribeType: BehaviorSubscribeType,
    Output,
    Failure: Error
  >: StreamHandlerType {

    // MARK: Lifecycle

    public init(
      onValue: @escaping @TreeActor (_ value: Output) -> Void,
      onFinish: @escaping @TreeActor () -> Void,
      onFailure: @escaping @TreeActor (_ failure: Error) -> Void,
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

    public typealias Output = Output

    @TreeActor
    public func cancel() {
      onCancel()
    }

    // MARK: Internal

    let onValue: @TreeActor (_ value: Output) -> Void
    let onFinish: @TreeActor () -> Void
    let onFailure: @TreeActor (_ error: any Error) -> Void
    let onCancel: @TreeActor () -> Void

  }
}
