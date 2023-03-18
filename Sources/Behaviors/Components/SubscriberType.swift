// MARK: - SubscriberType

@rethrows
public protocol SubscriberType<Input, Producer> {
  associatedtype Input
  associatedtype Producer
  init(_ type: @escaping (Input) async -> Producer)
  func subscribe(input: Input) async -> Producer
}

// MARK: - Behaviors.Subscriber

extension Behaviors {
  public struct Subscriber<Input, Producer>: SubscriberType {
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
