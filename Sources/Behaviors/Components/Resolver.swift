// MARK: - Resolver

public protocol Resolver<Value> {
  associatedtype Value
}

// MARK: - SingleResolver

public protocol SingleResolver<Value>: Resolver {
  associatedtype ResolveFunc
  var resolve: ResolveFunc { get }
}

// MARK: - EventualThrowing

public struct EventualThrowing<Value>: SingleResolver {
  public init(_ resolve: @escaping () async throws -> Value) {
    self.resolve = resolve
  }

  public let resolve: () async throws -> Value
  public typealias Value = Value
  public typealias ResolveFunc = () async throws -> Value
}

// MARK: - ImmediateThrowing

public struct ImmediateThrowing<Value>: SingleResolver {
  public init(_ resolve: @escaping () throws -> Value) {
    self.resolve = resolve
  }

  public var resolve: () throws -> Value

  public typealias Value = Value
  public typealias ResolveFunc = () throws -> Value
}

// MARK: - Eventual

public struct Eventual<Value>: SingleResolver {
  public init(_ resolve: @escaping () async -> Value) {
    self.resolve = resolve
  }

  public var resolve: () async -> Value

  public typealias Value = Value
  public typealias ResolveFunc = () async -> Value
}

// MARK: - Immediate

public struct Immediate<Value>: SingleResolver {
  public init(_ resolve: @escaping () -> Value) {
    self.resolve = resolve
  }

  public var resolve: () -> Value

  public typealias Value = Value
  public typealias ResolveFunc = () -> Value
}

// MARK: - IterationResolver

@rethrows
public protocol IterationResolver<Value>: Resolver {
  associatedtype Value
  func next() async throws -> Self?
  var value: Value { get }
}

// MARK: - RethrowsAsyncIteration

public struct RethrowsAsyncIteration<It: AsyncIteratorProtocol>: IterationResolver {
  public typealias Value = It.Element
  public let value: Value
  let iterator: It
  public func next() async rethrows -> Self? {
    var copy = iterator
    if let nextValue = try await copy.next() {
      return .init(value: nextValue, iterator: copy)
    } else {
      return nil
    }
  }
}

// MARK: - ThrowingIterationOf

public struct ThrowingIterationOf<Value>: IterationResolver {

  public init(value: Value, _ resolve: @escaping ResolveFunc) {
    self.resolve = resolve
    self.value = value
  }

  public let resolve: ResolveFunc
  public typealias Value = Value
  public typealias ResolveFunc = () async throws -> Self?
  public let value: Value
  public func next() async throws -> Self? {
    try await resolve()
  }
}

// MARK: - AlwaysIterationOf

public struct AlwaysIterationOf<Value>: IterationResolver {

  public init(value: Value, _ resolve: @escaping ResolveFunc) {
    self.resolve = resolve
    self.value = value
  }

  public let resolve: ResolveFunc
  public typealias Value = Value
  public typealias ResolveFunc = () async -> Self?
  public let value: Value
  public func next() async -> Self? {
    await resolve()
  }
}

// MARK: - Iteration

public struct Iteration<Underlying: IterationResolver>: IterationResolver {

  public init(_ underlying: Underlying) {
    self.underlying = underlying
  }

  private let underlying: Underlying
  public var value: Underlying.Value {
    underlying.value
  }

  public func next() async rethrows -> Self? {
    try await underlying.next().map { .init($0) }
  }
}
