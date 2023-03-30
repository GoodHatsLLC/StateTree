import Disposable
import TreeActor

// MARK: - BehaviorType

public protocol BehaviorType<Input, Output, Failure> {
  associatedtype Input
  associatedtype Output
  associatedtype Failure: Error
  associatedtype Producer
  associatedtype Subscriber: SubscriberType where Subscriber.Input == Input
  associatedtype Handler: HandlerType where Handler.Output == Output
  @_spi(Implementation)
  init(
    _ id: BehaviorID,
    subscriber: Subscriber
  )
  var id: BehaviorID { get }
  var subscriber: Subscriber { get }
}
