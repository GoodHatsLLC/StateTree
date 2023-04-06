// MARK: - SubscriberType

public protocol SubscriberType<Input, Producer> {
  associatedtype Input
  associatedtype Output
  associatedtype Failure: Error
  associatedtype Producer
}
