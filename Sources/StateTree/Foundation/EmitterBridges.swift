import Emitter
#if canImport(Combine)
import struct Combine.AnyPublisher
import protocol Combine.Publisher
#endif
import Utilities

// MARK: - CombineEmitterBridge

// TODO: move to Emitter
// TODO: remove .erase() export from disposable

public struct CombineEmitterBridge<Output: Sendable>: Emitter, @unchecked
Sendable {

  // MARK: Lifecycle

  public init(_ publisher: some Publisher<Output, some Error>) {
    self.publisher = publisher.mapError { $0 as Error }.eraseToAnyPublisher()
  }

  public init(_ publisher: some Publisher<Output, Never>) {
    self.publisher = publisher.setFailureType(to: Error.self).eraseToAnyPublisher()
  }

  // MARK: Public

  public func subscribe<S: Subscriber>(_ subscriber: S) -> AnyDisposable where Output == S.Value {
    let stage = DisposableStage()
    Emitters
      .create(Output.self) { emit in
        publisher
          .sink { completion in
            Task { @TreeActor in
              switch completion {
              case .finished:
                emit(.finished)
              case .failure(let error):
                emit(.failed(error))
              }
            }
          } receiveValue: { value in
            Task { @TreeActor in
              emit(.value(value))
            }
          }
          .stage(on: stage)
      }
      .subscribe(subscriber)
      .stage(on: stage)
    return stage.erase()
  }

  // MARK: Private

  private let publisher: AnyPublisher<Output, Error>

}

// MARK: - AsyncEmitterBridge

public struct AsyncEmitterBridge<Output: Sendable>: Emitter, @unchecked Sendable {
  public func subscribe<S: Subscriber>(_ subscriber: S) -> AnyDisposable where Output == S.Value {
    let stage = DisposableStage()
    Emitters
      .create(Output.self) { emit in
        Task { @TreeActor in
          do {
            for try await value in seq {
              emit(.value(value))
            }
            emit(.finished)
          } catch {
            emit(.failed(error))
          }
        }
        .erase() // TODO: remove Task.erase() from public API
        .stage(on: stage)
      }
      .subscribe(subscriber)
      .stage(on: stage)
    return stage.erase()
  }

  private let seq: AnyAsyncSequence<Output>

  public init<S: AsyncSequence>(_ sequence: S) where S.Element == Output {
    self.seq = AnyAsyncSequence(sequence)
  }
}
