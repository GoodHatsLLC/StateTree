import Disposable
import Foundation

// MARK: - AsyncSequenceBehavior

public struct AsyncSequenceBehavior<Input, Output>: BehaviorType {

  public init(
    id: BehaviorID,
    _ sequenceAction: @escaping @Sendable (Input) -> AnyAsyncSequence<Output>
  ) {
    self.id = id
    self.action = sequenceAction
    self.runner = RunnerActor(id: id)
  }

  public let id: BehaviorID
  public typealias Action = @Sendable (Input) -> AnyAsyncSequence<Output>
  public typealias Handler = AsyncSequenceHandler<Output>
  private let runner: RunnerActor
  public let action: @Sendable (Input) -> AnyAsyncSequence<Output>

}

// MARK: - Public API
extension AsyncSequenceBehavior {

  public func subscribe(handler: AsyncSequenceHandler<Output>) {
    Task {
      await runner
        .subscribe(handler: handler)
    }
  }

  /// - Parameters:
  ///   - onValue: A callback run each time the behavior's AsyncSequence emits a value.
  ///   - onFinish: A callback run once after the behavior has emitted its final value without
  /// failing.
  ///   - onCancel: A callback run once if the behavior is cancelled because its hosting ``Node`` is
  /// deactivated.
  ///   - onFailure: A callback run once if the behavior fails emitting an error.
  public func onValue(
    _ onValue: @escaping @Sendable @TreeActor (_ value: Output) -> Void,
    onFinish: @escaping @Sendable @TreeActor () -> Void = { },
    onCancel: @escaping @Sendable @TreeActor () -> Void = { },
    onFailure: @escaping @Sendable @TreeActor (_ error: Error) -> Void = { _ in }
  ) {
    subscribe(handler: .init(
      onValue: onValue,
      onFinish: onFinish,
      onCancel: onCancel,
      onFailure: onFailure
    ))
  }
}

// MARK: - AsyncSequenceHandler

public struct AsyncSequenceHandler<Output>: BehaviorHandler {
  public typealias Failure = Error
  public init(
    onValue: @escaping @TreeActor (Output) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onCancel: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (Error) -> Void = { _ in }
  ) {
    self.onValue = onValue
    self.onFinish = onFinish
    self.onCancel = onCancel
    self.onFailure = onFailure
  }

  let onValue: @TreeActor (_ value: Output) -> Void
  let onFinish: @TreeActor () -> Void
  let onCancel: @TreeActor () -> Void
  let onFailure: @TreeActor (_ error: Error) -> Void
}

// MARK: - API
extension AsyncSequenceBehavior {

  public nonisolated func dispose() {
    Task {
      await runner.finish(wasCancelled: true)
    }
  }

  @TreeActor
  public func run(on scope: some Scoping, input: Input) {
    let action = scope.host(behavior: self, input: input) ?? action
    Task { @TreeActor in
      _ = await runner.run(action: { AnyAsyncSequence<Output>(action(input)) })
    }
  }

  public func resolution() async -> BehaviorResolution {
    await runner.resolution.value
  }

}

// MARK: - AsyncSequenceBehavior.RunnerActor

extension AsyncSequenceBehavior {

  private actor RunnerActor {

    // MARK: Lifecycle

    init(id: BehaviorID) {
      self.id = id
    }

    // MARK: Public

    public func subscribe(handler: AsyncSequenceHandler<Output>) {
      switch lifeState {
      case .running,
           .unstarted:
        handlers.append(handler)
      case .finished(let wasCancelled):
        Task { @TreeActor [handler] in
          if wasCancelled {
            handler.onCancel()
          } else {
            handler.onFinish()
          }
        }
      case .failed(let error):
        Task { @TreeActor [handler, error] in
          handler.onFailure(error)
        }
      }
    }

    // MARK: Internal

    let id: BehaviorID
    let resolution = AsyncValue<BehaviorResolution>()

    func run(
      action: @escaping @Sendable () -> AnyAsyncSequence<Output>
    ) async
      -> Bool
    {
      lifeState.startIfPossible {
        Task {
          await withTaskCancellationHandler {
            do {
              for try await item in action() {
                emit(value: item)
              }
              finish(wasCancelled: false)
            } catch {
              fail(error: error)
            }
          } onCancel: {
            Task {
              await finish(wasCancelled: true)
            }
          }
        }
      }
    }

    func finish(wasCancelled: Bool) {
      if let value = lifeState.finish(id: id, wasCancelled: wasCancelled) {
        let handlers = handlers
        self.handlers = []
        Task { @TreeActor [handlers, wasCancelled] in
          for handler in handlers {
            if wasCancelled {
              handler.onCancel()
            } else {
              handler.onFinish()
            }
          }
          await resolution.resolve(value)
        }
      }
    }

    // MARK: Private

    private var lifeState: LifeState = .unstarted
    private var handlers: [AsyncSequenceHandler<Output>] = []

    private func emit(value: Output) {
      switch lifeState {
      case .failed,
           .finished,
           .unstarted:
        break
      case .running:
        let handlers = handlers
        Task { @TreeActor [handlers, value] in
          for handler in handlers {
            handler.onValue(value)
          }
        }
      }
    }

    private func fail(error: some Error) {
      if let value = lifeState.fail(id: id, error: error) {
        let handlers = handlers
        self.handlers = []
        Task { @TreeActor [handlers, error, value] in
          for handler in handlers {
            handler.onFailure(error)
          }
          await resolution.resolve(value)
        }
      }
    }

  }
}

// MARK: - AsyncSequenceBehavior.LifeState

extension AsyncSequenceBehavior {

  private enum LifeState {
    case unstarted
    case running(handle: Task<Void, Never>, startTime: Double)
    case finished(wasCancelled: Bool)
    case failed(error: any Error)

    // MARK: Internal

    mutating func startIfPossible(handle: () -> Task<Void, Never>) -> Bool {
      switch self {
      case .failed,
           .finished,
           .running:
        return false
      case .unstarted:
        self = .running(handle: handle(), startTime: CFAbsoluteTimeGetCurrent())
        return true
      }
    }

    mutating func fail(id: BehaviorID, error: any Error) -> BehaviorResolution? {
      switch self {
      case .failed,
           .finished:
        return nil
      case .unstarted:
        self = .failed(error: error)
        return BehaviorResolution(
          id: id,
          resolution: .failed,
          startTime: nil,
          endTime: CFAbsoluteTimeGetCurrent()
        )
      case .running(handle: let handle, startTime: let startTime):
        handle.cancel()
        self = .failed(error: error)
        return BehaviorResolution(
          id: id,
          resolution: .failed,
          startTime: startTime,
          endTime: CFAbsoluteTimeGetCurrent()
        )
      }
    }

    mutating func finish(id: BehaviorID, wasCancelled: Bool) -> BehaviorResolution? {
      switch self {
      case .failed,
           .finished:
        return nil
      case .unstarted:
        self = .finished(wasCancelled: wasCancelled)
        return BehaviorResolution(
          id: id,
          resolution: wasCancelled ? .cancelled : .finished,
          startTime: nil,
          endTime: CFAbsoluteTimeGetCurrent()
        )
      case .running(handle: let handle, startTime: let startTime):
        handle.cancel()
        self = .finished(wasCancelled: wasCancelled)
        return BehaviorResolution(
          id: id,
          resolution: wasCancelled ? .cancelled : .finished,
          startTime: startTime,
          endTime: CFAbsoluteTimeGetCurrent()
        )
      }
    }

  }
}
