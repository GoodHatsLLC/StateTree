// MARK: - One

public struct One<Output, Failure: Error> {
  fileprivate init(resolver: Any) {
    self.resolver = resolver
  }

  let resolver: Any
}

extension One where Failure == Never {

  // MARK: Public

  public func resolve() async -> Output {
    await (resolver as! () async -> Output)()
  }

  // MARK: Internal

  static func always(action: @escaping () async throws -> Output) -> One<Output, Never>
    where Failure == Never
  {
    .init(resolver: action)
  }

}

extension One where Failure: Error {

  // MARK: Public

  public func resolve() async throws -> Output {
    try await (resolver as! () async throws -> Output)()
  }

  // MARK: Internal

  static func throwing(action: @escaping () async throws -> Output) -> One<Output, Error>
    where Failure == Error
  {
    .init(resolver: action)
  }

}

// MARK: - Behaviors.Make.Func

extension Behaviors.Make {
  public enum Func {
    public typealias NonThrowing = (_ input: Input) async -> Output
    public typealias Throwing = (_ input: Input) async throws -> Output
  }
}
