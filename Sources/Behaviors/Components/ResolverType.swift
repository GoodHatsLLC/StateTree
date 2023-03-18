// MARK: - ResolverType

public protocol ResolverType<Value> {
  associatedtype Value
  associatedtype ResolveFunc
}

// MARK: - SingleResolverType

public protocol SingleResolverType<Value>: ResolverType {
  var resolve: ResolveFunc { get }
}

// MARK: - EventualThrowing

public struct EventualThrowing<Value>: SingleResolverType {
  public init(_ resolve: @escaping () async throws -> Value) {
    self.resolve = resolve
  }

  public let resolve: () async throws -> Value
  public typealias Value = Value
  public typealias ResolveFunc = () async throws -> Value
}

// MARK: - Eventual

public struct Eventual<Value>: SingleResolverType {
  public init(_ resolve: @escaping () async -> Value) {
    self.resolve = resolve
  }

  public var resolve: () async -> Value
  public typealias Value = Value
  public typealias ResolveFunc = () async -> Value
}
