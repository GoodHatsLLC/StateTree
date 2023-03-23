import TreeActor

// MARK: - AsyncOne

public struct AsyncOne<Output, Failure: Error> {
  fileprivate init(resolver: Any) {
    self.resolver = resolver
  }

  let resolver: Any
}

extension AsyncOne where Failure == Never {

  public static func always(action: @escaping () async throws -> Output) -> AsyncOne<Output, Never>
    where Failure == Never
  {
    .init(resolver: action)
  }

  public func resolve() async -> Output {
    await (resolver as! () async -> Output)()
  }

}

extension AsyncOne where Failure: Error {

  public static func throwing(action: @escaping () async throws -> Output)
    -> AsyncOne<Output, Error>
    where Failure == Error
  {
    .init(resolver: action)
  }

  public func resolve() async throws -> Output {
    try await (resolver as! () async throws -> Output)()
  }

}

// MARK: - SyncOne

public struct SyncOne<Output, Failure: Error> {
  private init(resolver: Any) {
    self.resolver = resolver
  }

  let resolver: Any
}

extension SyncOne where Failure == Never {

  public static func always(action: @escaping () throws -> Output) -> SyncOne<Output, Never>
    where Failure == Never
  {
    .init(resolver: action)
  }

  public func resolve() -> Output {
    (resolver as! () -> Output)()
  }

}

extension SyncOne where Failure: Error {

  public static func throwing(action: @escaping () throws -> Output) -> SyncOne<Output, Error>
    where Failure == Error
  {
    .init(resolver: action)
  }

  public func resolve() throws -> Output {
    try (resolver as! () throws -> Output)()
  }

}
