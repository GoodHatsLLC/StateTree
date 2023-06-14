import Foundation

/// A type erased `AsyncSequence`
///
/// This type allows you to create APIs that return an `AsyncSequence` that allows consumers to
/// iterate over the sequence, without exposing the sequence's underlying type.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AnyAsyncSequence<Element>: AsyncSequence {

  // MARK: Lifecycle

  // MARK: - Initializers

  /// Create an `AnyAsyncSequence` from an `AsyncSequence` conforming type
  /// - Parameter sequence: The `AnySequence` type you wish to erase
  public init<T: AsyncSequence>(_ sequence: T) where T.Element == Element {
    self.makeAsyncIteratorClosure = { AnyAsyncIterator(sequence.makeAsyncIterator()) }
  }

  public init(_ sequence: some Sequence<Element>) {
    let asyncSeq = AsyncStream<Element> { continuation in
      for element in sequence {
        continuation.yield(element)
      }
      continuation.finish()
    }
    self.init(asyncSeq)
  }

  // MARK: Public

  // MARK: - API

  public struct AnyAsyncIterator: AsyncIteratorProtocol {
    private let nextClosure: () async throws -> Element?

    public init<T: AsyncIteratorProtocol>(_ iterator: T) where T.Element == Element {
      var iterator = iterator
      self.nextClosure = { try await iterator.next() }
    }

    public func next() async throws -> Element? {
      try await nextClosure()
    }
  }

  // MARK: - AsyncSequence

  public typealias Element = Element

  public typealias AsyncIterator = AnyAsyncIterator

  public func makeAsyncIterator() -> AsyncIterator {
    AnyAsyncIterator(makeAsyncIteratorClosure())
  }

  // MARK: Private

  private let makeAsyncIteratorClosure: () -> AsyncIterator

}
