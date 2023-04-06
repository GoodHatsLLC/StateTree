import TreeActor
import Utilities

// MARK: - Behaviors

public enum Behaviors {
  public struct Cancellation: Error, Equatable { }
  public static let cancellation = Cancellation()
}

extension Behaviors {
  public struct SyncSubscriber<Input, Output, Failure: Error>: SubscriberType {
    public typealias Input = Input
    public typealias Output = Output
    public typealias Failure = Failure
    public typealias Producer = SyncOne<Output, Failure>

    init(_ type: @escaping @TreeActor (Input) -> Producer) {
      self.subscribeFunc = type
    }

    private let subscribeFunc: @TreeActor (Input) -> Producer
    @TreeActor
    func subscribe(input: Input) -> Producer {
      subscribeFunc(input)
    }
  }

  public struct AsyncSubscriber<Input, Output, Failure: Error>: SubscriberType {
    public typealias Input = Input
    public typealias Output = Output
    public typealias Failure = Failure
    public typealias Producer = AsyncOne<Output, Failure>
    init(_ type: @escaping Behaviors.Make<Input, Output>.AsyncFunc.NonThrowing)
      where Failure == Never
    {
      self.subscribeFunc = { input in .always { await type(input) } }
    }

    init(_ type: @escaping Behaviors.Make<Input, Output>.AsyncFunc.Throwing)
      where Failure == Error
    {
      self.subscribeFunc = { input in .throwing { try await type(input) } }
    }

    private let subscribeFunc: (Input) async -> Producer
    func subscribe(input: Input) async -> Producer {
      await subscribeFunc(input)
    }
  }

  public struct StreamSubscriber<Input, Output, Failure: Error>: SubscriberType {
    public typealias Input = Input
    public typealias Output = Output
    public typealias Failure = Failure
    public typealias Producer = AnyAsyncSequence<Output>
    init<Seq: AsyncSequence>(
      _ type: @escaping Behaviors.Make<Input, Output>.StreamFunc
        .Concrete<Seq>
    ) where Seq.Element == Output {
      self.subscribeFunc = { input in await AnyAsyncSequence(type(input)) }
    }

    private let subscribeFunc: Behaviors.Make<Input, Output>.StreamFunc.Erased
    func subscribe(input: Input) async -> Producer {
      await subscribeFunc(input)
    }
  }
}

// MARK: Behaviors.Make

extension Behaviors {
  public enum Make<Input, Output> {

    public enum StreamFunc {
      public typealias Concrete<Seq: AsyncSequence> = (_ input: Input) async -> Seq
        where Seq.Element == Output
      public typealias Erased = (_ input: Input) async -> AnyAsyncSequence<Output>
    }

    public enum SyncFunc {
      public typealias NonThrowing = @TreeActor (_ input: Input) -> Output
      public typealias Throwing = @TreeActor (_ input: Input) throws -> Output
    }

    public enum AsyncFunc {
      public typealias NonThrowing = (_ input: Input) async -> Output
      public typealias Throwing = (_ input: Input) async throws -> Output
    }
  }
}
