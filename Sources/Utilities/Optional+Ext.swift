
extension Optional {
  public func orThrow(_ error: Error? = nil) throws -> Wrapped {
    switch self {
    case .none:
      if let error {
        throw error
      } else {
        throw OptionalUnwrappingError(Wrapped.self)
      }
    case .some(let wrapped):
      return wrapped
    }
  }

  public func unwrappingResult() -> Result<Wrapped, OptionalUnwrappingError<Wrapped>> {
    switch self {
    case .none:
      return .failure(OptionalUnwrappingError(Wrapped.self))
    case .some(let wrapped):
      return .success(wrapped)
    }
  }
}

// MARK: - OptionalUnwrappingError

public struct OptionalUnwrappingError<T>: Error {
  public init(_: T.Type) { }
  public let description = "Could not unwrap \(T.self)?"
}
