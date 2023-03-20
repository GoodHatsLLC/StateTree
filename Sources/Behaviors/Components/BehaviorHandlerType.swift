import TreeActor

// MARK: - HandlerType

public protocol HandlerType {
  associatedtype Output
  associatedtype Failure: Error
  init()
  func cancel() async
}

// MARK: - SingleHandlerType

public protocol SingleHandlerType: HandlerType where Failure == Never {
  init(
    onSuccess: @escaping @TreeActor (Output) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  )
}

// MARK: - ThrowingSingleHandlerType

public protocol ThrowingSingleHandlerType: HandlerType where Failure: Error {
  init(
    onResult: @escaping @TreeActor (Result<Output, Error>) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  )
}

// MARK: - StreamHandlerType

public protocol StreamHandlerType: HandlerType {
  init(
    onValue: @escaping @TreeActor (Output) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onCancel: @escaping @TreeActor () -> Void
  )
}

// MARK: - ThrowingStreamHandlerType

public protocol ThrowingStreamHandlerType: HandlerType {
  init(
    onValue: @escaping @TreeActor (Output) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (any Error) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  )
}
