import Disposable

// MARK: - BehaviorProducerType

public protocol BehaviorProducerType<Input, Event> {
  associatedtype Input: Sendable
  associatedtype Event: BehaviorEventType
  associatedtype Handler: BehaviorHandlerType where Handler.Event == Event

  func start(input: Input, handler: Handler) -> AnyDisposable
}
