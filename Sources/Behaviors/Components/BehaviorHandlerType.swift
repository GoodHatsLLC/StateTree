import TreeActor

// MARK: - HandlerType

public protocol HandlerType {
  associatedtype Value = Producer.Resolution.Value
  associatedtype Producer: ProducerType
  associatedtype Behavior: BehaviorType where Behavior.Handler == Self
  init()
  func cancel() async
}

// MARK: - SingleHandlerType

public protocol SingleHandlerType: HandlerType {
  init(onSuccess: @escaping @TreeActor (Value) -> Void, onCancel: @escaping @TreeActor () -> Void)
}

// MARK: - ThrowingSingleHandlerType

public protocol ThrowingSingleHandlerType: HandlerType {
  init(
    onResult: @escaping @TreeActor (Result<Value, Error>) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  )
}

// MARK: - StreamHandlerType

public protocol StreamHandlerType: HandlerType {
  init(
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onCancel: @escaping @TreeActor () -> Void
  )
}

// MARK: - ThrowingStreamHandlerType

public protocol ThrowingStreamHandlerType: HandlerType {
  init(
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (any Error) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  )
}
