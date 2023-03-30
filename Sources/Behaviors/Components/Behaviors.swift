import TreeActor
import Utilities

// MARK: - Behaviors

public enum Behaviors {
  public struct Cancellation: Error, Equatable { }
  public static let cancellation = Cancellation()
  public enum Throwing { }
}

extension Behaviors {
  public struct SyncSubscriber<Input, Producer>: SubscriberType {
    public init(_ type: @escaping (Input) -> Producer) {
      self.subscribeFunc = type
    }

    private let subscribeFunc: (Input) -> Producer
    public func subscribe(input: Input) -> Producer {
      subscribeFunc(input)
    }
  }

  public struct AsyncSubscriber<Input, Producer>: SubscriberType {
    public init(_ type: @escaping (Input) async -> Producer) {
      self.subscribeFunc = type
    }

    private let subscribeFunc: (Input) async -> Producer
    public func subscribe(input: Input) async -> Producer {
      await subscribeFunc(input)
    }
  }

  public struct StreamSubscriber<Input, Producer: AsyncSequence>: SubscriberType {
    public init(_ type: @escaping (Input) async -> Producer) {
      self.subscribeFunc = type
    }

    private let subscribeFunc: (Input) async -> Producer
    public func subscribe(input: Input) async -> Producer {
      await subscribeFunc(input)
    }
  }
}

// MARK: Behaviors.Make

extension Behaviors {
  public enum Make<Input, Output> { }
}

// MARK: - Behaviors.Make

extension Behaviors.Make {

  public typealias StreamFunc = (_ input: Input) async -> AnyAsyncSequence<Output>

  public enum SyncFunc {
    public typealias NonThrowing = @TreeActor (_ input: Input) -> Output
    public typealias Throwing = @TreeActor (_ input: Input) throws -> Output
  }

  public enum AsyncFunc {
    public typealias NonThrowing = (_ input: Input) async -> Output
    public typealias Throwing = (_ input: Input) async throws -> Output
  }
}
