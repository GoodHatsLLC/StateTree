// MARK: - AnyAsyncSequence

/// A type erased AsyncSequence
///
/// As of Swift 5.7 The AsyncSequence protocol doesn't have a  primary associated type.
public struct AnyAsyncSequence<Element>: AsyncSequence {

  init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
    self.iteratorFunc = { AnyAsyncIterator(sequence.makeAsyncIterator()) }
  }

  public func makeAsyncIterator() -> AnyAsyncIterator {
    AnyAsyncIterator(iteratorFunc())
  }

  public struct AnyAsyncIterator: AsyncIteratorProtocol {
    private let nextFunc: () async throws -> Element?

    init<T: AsyncIteratorProtocol>(_ iterator: T) where T.Element == Element {
      var iterator = iterator
      self.nextFunc = { try await iterator.next() }
    }

    public func next() async throws -> Element? {
      try await nextFunc()
    }
  }

  private let iteratorFunc: () -> AsyncIterator

}

extension AsyncSequence {
  public func erase() -> AnyAsyncSequence<Element> {
    .init(self)
  }
}
