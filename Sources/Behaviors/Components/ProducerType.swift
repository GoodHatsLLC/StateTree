// MARK: - ProducerType

public protocol ProducerType<Resolution> {
  associatedtype Resolution: Resolver
}

// MARK: - SingleProducerType

public protocol SingleProducerType<Resolution>: ProducerType where Resolution: SingleResolver {
  var value: Resolution { get }
}

// MARK: - OnlyOne

public struct OnlyOne<Resolution: SingleResolver>: SingleProducerType {
  public let value: Resolution
}

// MARK: - IteratorType

@rethrows
public protocol IteratorType<Resolution>: ProducerType
  where Resolution: IterationResolver
{
  func first() async throws -> Resolution?
}

// MARK: - AlwaysIteratorOf

public struct AlwaysIteratorOf<T>: IteratorType {

  let resolveFunc: () async -> AlwaysIterationOf<T>?

  public typealias Resolution = AlwaysIterationOf<T>
  public func first() async -> Resolution? {
    await resolveFunc()
  }
}

// MARK: - ThrowingIteratorOf

public struct ThrowingIteratorOf<T>: IteratorType {

  let resolveFunc: () async throws -> ThrowingIterationOf<T>?

  public typealias Resolution = ThrowingIterationOf<T>
  public func first() async throws -> Resolution? {
    try await resolveFunc()
  }
}

// MARK: - IteratorOf

public struct IteratorOf<I: IteratorType>: IteratorType {
  init(_ underlying: I) {
    self.underlying = underlying
  }

  private let underlying: I
  public func first() async rethrows -> I.Resolution? {
    try await underlying.first()
  }

  public typealias Resolution = I.Resolution
}
