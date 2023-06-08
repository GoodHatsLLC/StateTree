#if canImport(Combine)
import Combine
extension Async {
  public enum Combine {
    /// Make an unbounded async-safe publisher -> async bridge.
    ///
    /// This bridge creates an async sequence which uses an intermediate subscription
    /// on the current actor to receive values from the publisher—and reemits the received values.
    ///
    /// Publishers like `PassthroughSubject` and `CurrentValueSubject` whose
    /// emissions are not all sent from the same actor will drop values when bridged with `.values`.
    public static func bridge<Value>(publisher: some Publisher<Value, Never>) -> Async
      .Subject<Value>
    {
      let asyncSubject = Async.Subject<Value>()
      var sub: (any Cancellable)?
      sub = publisher
        .sink { completion in
          switch completion {
          case .finished:
            asyncSubject.finish()
          }
          sub?.cancel()
        } receiveValue: { value in
          asyncSubject.send(value)
        }
      return asyncSubject
    }

    /// Make an unbounded async-safe publisher -> async bridge.
    ///
    /// This bridge creates an async sequence which uses an intermediate subscription
    /// on the current actor to receive values from the publisher—and reemits the received values.
    ///
    /// Publishers like `PassthroughSubject` and `CurrentValueSubject` whose
    /// emissions are not all sent from the same actor will drop values when bridged with `.values`.
    public static func bridge<Value>(publisher: some Publisher<Value, some Error>) -> Async
      .ThrowingSubject<Value>
    {
      let asyncSubject = Async.ThrowingSubject<Value>()
      var sub: (any Cancellable)?
      sub = publisher
        .sink { completion in
          switch completion {
          case .finished:
            asyncSubject.finish()
          case .failure(let err):
            asyncSubject.fail(err)
          }
          sub?.cancel()
        } receiveValue: { value in
          asyncSubject.send(value)
        }
      return asyncSubject
    }
  }
}

#endif
