import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - Behaviors.Stream

extension Behaviors {
  public struct Stream<Input, Output>: StreamBehaviorType {

    // MARK: Lifecycle

    public init(_ id: BehaviorID, subscriber: Behaviors.StreamSubscriber<Input, Producer>) {
      self.id = id
      self.subscriber = subscriber
    }

    // MARK: Public

    public typealias Producer = AnyAsyncSequence<Output>
    public typealias Input = Input
    public typealias Output = Output
    public typealias Failure = Error
    public typealias Func = (_ input: Input) async -> Producer
    public typealias Subscriber = Behaviors.StreamSubscriber<Input, Producer>
    public typealias Resolution = Producer.Element
    public struct Handler: StreamHandlerType {

      // MARK: Lifecycle

      public init(
        onValue: @escaping @TreeActor (Output) -> Void,
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

      public typealias Failure = Error

      public typealias Behavior = Stream<Input, Output>
      public typealias Output = Producer.Element

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
    _ id: BehaviorID? = nil,
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) async -> Seq
  ) -> Behaviors.Stream<Input, Seq.Element> {
    let id = id ?? .meta(fileID: fileID, line: line, column: column, meta: "as-stream")
    return .init(id, subscriber: .init { await AnyAsyncSequence<Seq.Element>(subscribe($0)) })
  }

  public static func make<Input, Seq: AsyncSequence>(
    _ id: BehaviorID? = nil,
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) -> Seq
  ) -> Behaviors.Stream<Input, Seq.Element> {
    let id = id ?? .meta(fileID: fileID, line: line, column: column, meta: "as-stream")
    return .init(id, subscriber: .init { AnyAsyncSequence<Seq.Element>(subscribe($0)) })
  }

  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) async -> some Emitting<Output>
  ) -> Behaviors.Stream<Input, Output> {
    let id = id ?? .meta(fileID: fileID, line: line, column: column, meta: "e-stream")
    return Behaviors.make(id) {
      await subscribe($0).values
    }
  }

  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) -> some Emitting<Output>
  ) -> Behaviors.Stream<Input, Output> {
    let id = id ?? .meta(fileID: fileID, line: line, column: column, meta: "e-stream")
    return Behaviors.make(id) {
      subscribe($0).values
    }
  }

}

#if canImport(Combine)
import Combine
extension Behaviors {
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) async -> some Publisher<Output, Never>
  ) -> Behaviors.Stream<Input, Output> {
    let id = id ?? .meta(fileID: fileID, line: line, column: column, meta: "e-stream")
    return Behaviors.make(id) {
      await Async.Combine.bridge(publisher: subscribe($0))
    }
  }

  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) -> some Publisher<Output, Never>
  ) -> Behaviors.Stream<Input, Output> {
    let id = id ?? .meta(fileID: fileID, line: line, column: column, meta: "e-stream")
    return Behaviors.make(id) {
      Async.Combine.bridge(publisher: subscribe($0))
    }
  }
}

#endif
