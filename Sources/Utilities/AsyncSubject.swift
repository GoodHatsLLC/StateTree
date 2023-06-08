// MARK: - Async.ThrowingSubject

extension Async {

  public struct ThrowingSubject<Element>: AsyncSequence, @unchecked Sendable {

    public typealias AsyncIterator = AsyncThrowingStream<Element, any Error>.Iterator

    private let continuation: AsyncThrowingStream<Element, any Error>.Continuation?
    private let stream: AsyncThrowingStream<Element, any Error>

    public init() {
      var continuation: AsyncThrowingStream<Element, any Error>.Continuation?
      self.stream = AsyncThrowingStream(bufferingPolicy: .unbounded) { continuation = $0 }
      self.continuation = continuation
    }

    public func makeAsyncIterator() -> AsyncThrowingStream<Element, any Error>.Iterator {
      stream.makeAsyncIterator()
    }

    public func send(_ value: Element) {
      continuation?.yield(value)
    }

    public func fail(_ error: any Error) {
      continuation?.finish(throwing: error)
    }

    public func finish() {
      continuation?.finish(throwing: nil)
    }
  }
}

// MARK: - Async.Subject

extension Async {

  public struct Subject<Element>: AsyncSequence, @unchecked Sendable {

    public typealias AsyncIterator = AsyncStream<Element>.Iterator

    private let continuation: AsyncStream<Element>.Continuation?
    private let stream: AsyncStream<Element>

    public init() {
      var continuation: AsyncStream<Element>.Continuation?
      self.stream = AsyncStream(bufferingPolicy: .unbounded) { continuation = $0 }
      self.continuation = continuation
    }

    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
      stream.makeAsyncIterator()
    }

    public func send(_ value: Element) {
      continuation?.yield(value)
    }

    public func finish() {
      continuation?.finish()
    }
  }

}
