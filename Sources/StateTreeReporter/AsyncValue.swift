public actor AsyncThrowingValue<Output: Sendable> {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var value: Output {
    get async throws {
      if let _value {
        return try _value.get()
      } else {
        return try await withCheckedThrowingContinuation { continuation in
          self.continuation = continuation
        }
      }
    }
  }

  public nonisolated func resolve(_ value: Output) {
    Task {
      await setFinal(value: .success(value))
    }
  }

  public nonisolated func fail(_ error: Error) {
    Task {
      await setFinal(value: .failure(error))
    }
  }

  // MARK: Private

  private var _value: Result<Output, Error>?
  private var continuation: CheckedContinuation<Output, Error>?

  private func setFinal(value: Result<Output, Error>) {
    guard _value == nil
    else {
      return
    }
    _value = value
    continuation?.resume(with: value)
  }

}
