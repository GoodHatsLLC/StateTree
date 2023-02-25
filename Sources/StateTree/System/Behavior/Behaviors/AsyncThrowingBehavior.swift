import Disposable
import Foundation

// MARK: - AsyncThrowingBehavior

public struct AsyncThrowingBehavior<Input: Sendable, Output: Sendable>: BehaviorType, Sendable {

  // MARK: Lifecycle

  public init(
    id: BehaviorID,
    _ action: @escaping @Sendable (Input) async throws -> Output
  ) {
    self.id = id
    self.action = action
    self.runner = RunnerActor(id: id)
  }

  // MARK: Public

  public typealias Action = @Sendable (Input) async throws -> Output
  public typealias Handler = AsyncThrowingHandler<Output>
  public let id: BehaviorID

  // MARK: Private

  private let runner: RunnerActor
  public let action: @Sendable (Input) async throws -> Output

}

// MARK: - Public API
extension AsyncThrowingBehavior {

  /// - Parameters:
  ///   - onFinish: A callback run when the behavior either completes with a value or fails throwing
  /// an error.
  ///   - onCancel: A callback run if the behavior is cancelled because its hosting ``Node`` is
  /// deactivated.
  public func onCompletion(
    _ onCompletion: @escaping @Sendable @TreeActor (_ result: Result<Output, any Error>) -> Void,
    onCancel: @escaping @Sendable @TreeActor () -> Void = { }
  ) {
    subscribe(
      handler: AsyncThrowingHandler<Output>(
        onCompletion: onCompletion,
        onCancel: onCancel
      )
    )
  }

  public func subscribe(handler: AsyncThrowingHandler<Output>) {
    Task {
      await runner.subscribe(handler: handler)
    }
  }
}

// MARK: - AsyncThrowingHandler

public struct AsyncThrowingHandler<Output>: BehaviorHandler, Sendable {

  public typealias Failure = Error

  public init(
    onCompletion: @escaping @Sendable @TreeActor (Result<Output, Error>) -> Void,
    onCancel: @escaping @Sendable @TreeActor () -> Void = { }
  ) {
    self.onCompletion = onCompletion
    self.onCancel = onCancel
  }

  let onCompletion: @Sendable @TreeActor (_ result: Result<Output, any Error>) -> Void
  let onCancel: @Sendable @TreeActor () -> Void
}

// MARK: - API
extension AsyncThrowingBehavior {

  public nonisolated func dispose() {
    Task {
      await runner.cancel()
    }
  }

  @TreeActor
  public func run(on scope: some Scoping, input: Input) {
    let action = scope.host(behavior: self, input: input) ?? action
    Task { @TreeActor in
      _ = await runner.run(action: action, input: input)
    }
  }

  public func resolution() async -> BehaviorResolution {
    await runner.resolution.value
  }

}

// MARK: - AsyncThrowingBehavior.RunnerActor

extension AsyncThrowingBehavior {

  private actor RunnerActor {

    // MARK: Lifecycle

    init(id: BehaviorID) {
      self.id = id
    }

    // MARK: Public

    public func subscribe(handler: AsyncThrowingHandler<Output>) {
      switch lifeState {
      case .running,
           .unstarted:
        handlers.append(handler)
      case .cancelled:
        Task { @TreeActor [handler] in
          handler.onCancel()
        }
      case .finished(result: let result):
        Task { @TreeActor [handler, result] in
          handler.onCompletion(result)
        }
      }
    }

    // MARK: Internal

    let id: BehaviorID
    let resolution = AsyncValue<BehaviorResolution>()

    func run(
      action: @escaping @Sendable (Input) async throws -> Output,
      input: Input
    ) async
      -> Bool
    {
      lifeState.start {
        Task {
          await withTaskCancellationHandler {
            do {
              let value = try await action(input)
              self.finish(result: .success(value))
            } catch {
              self.finish(result: .failure(error))
            }
          } onCancel: {
            Task {
              await self.cancel()
            }
          }
        }
      }
    }

    func cancel() {
      if let value = lifeState.cancel(id: id) {
        let handlers = handlers
        self.handlers = []
        Task { @TreeActor [handlers] in
          for handler in handlers {
            handler.onCancel()
          }
          await resolution.resolve(value)
        }
      }
    }

    // MARK: Private

    private var lifeState: LifeState = .unstarted
    private var handlers: [AsyncThrowingHandler<Output>] = []

    private func finish(result: Result<Output, any Error>) {
      if let value = lifeState.finish(id: id, result: result) {
        Task { @TreeActor [handlers] in
          guard !Task.isCancelled
          else {
            return
          }
          for handler in handlers {
            handler.onCompletion(result)
          }
          await resolution.resolve(value)
        }
      }
    }
  }
}

// MARK: - AsyncThrowingBehavior.LifeState

extension AsyncThrowingBehavior {
  private enum LifeState {
    case unstarted
    case running(handle: Task<Void, Never>, startTime: Double)
    case finished(result: Result<Output, any Error>)
    case cancelled

    // MARK: Internal

    mutating func start(handle: () -> Task<Void, Never>) -> Bool {
      switch self {
      case .cancelled,
           .finished,
           .running:
        return false
      case .unstarted:
        self = .running(handle: handle(), startTime: CFAbsoluteTimeGetCurrent())
        return true
      }
    }

    mutating func finish(
      id: BehaviorID, result: Result<Output, any Error>
    )
      -> BehaviorResolution?
    {
      switch self {
      case .cancelled,
           .finished:
        return nil
      case .unstarted:
        self = .finished(result: result)
        return BehaviorResolution(
          id: id,
          resolution: .finished,
          startTime: nil,
          endTime: CFAbsoluteTimeGetCurrent()
        )
      case .running(
        handle: let handle,
        startTime: let startTime
      ):
        handle.cancel()
        self = .finished(result: result)
        return BehaviorResolution(
          id: id,
          resolution: ((try? result.get()) != nil) ? .finished : .failed,
          startTime: startTime,
          endTime: CFAbsoluteTimeGetCurrent()
        )
      }
    }

    mutating func cancel(id: BehaviorID) -> BehaviorResolution? {
      switch self {
      case .cancelled,
           .finished:
        return nil
      case .running(handle: let handle, startTime: let startTime):
        handle.cancel()
        self = .cancelled
        return BehaviorResolution(
          id: id,
          resolution: .cancelled,
          startTime: startTime,
          endTime: CFAbsoluteTimeGetCurrent()
        )
      case .unstarted:
        self = .cancelled
        return BehaviorResolution(
          id: id,
          resolution: .cancelled,
          startTime: nil,
          endTime: CFAbsoluteTimeGetCurrent()
        )
      }
    }
  }
}
