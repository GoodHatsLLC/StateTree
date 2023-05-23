@_spi(Implementation)
extension Optional {
  public func orThrow(_ error: Error) throws -> Wrapped {
    switch self {
    case .none:
      throw error
    case .some(let wrapped):
      return wrapped
    }
  }
}
