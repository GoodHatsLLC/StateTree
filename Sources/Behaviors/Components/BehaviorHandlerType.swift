import TreeActor

// MARK: - HandlerType

public protocol HandlerType<Output, Failure> {
  associatedtype Output
  associatedtype Failure: Error
  init()
  func cancel()
}

// MARK: - SingleHandlerType

public protocol SingleHandlerType: HandlerType {
  init(
    onResult: @escaping @TreeActor (Result<Output, Failure>) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  )
}

extension SingleHandlerType where Failure == Never {
  public init(
    onSuccess: @escaping @TreeActor (Output) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  ) {
    self.init(onResult: { result in
      switch result {
      case .success(let output):
        onSuccess(output)
      }
    }, onCancel: onCancel)
  }
}

// MARK: - StreamHandlerType

public protocol StreamHandlerType: HandlerType {
  init(
    onValue: @escaping @TreeActor (Output) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (any Error) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  )
}
