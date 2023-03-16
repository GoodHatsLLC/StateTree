// MARK: - SubscriberType

public protocol SubscriberType<Input, Producer> {
  associatedtype Input
  associatedtype Producer: ProducerType
  func subscribe(input: Input) async -> Producer
}

// MARK: - Behaviors.Subscriber

extension Behaviors {
  public struct Subscriber<Input, Producer: ProducerType>: SubscriberType {
    public typealias SubscriberFunc = (Input) async -> Producer
    init(_ type: @escaping SubscriberFunc) {
      self.subscribeFunc = type
    }

    private let subscribeFunc: SubscriberFunc
    public func subscribe(input: Input) async -> Producer {
      await subscribeFunc(input)
    }
  }
}
