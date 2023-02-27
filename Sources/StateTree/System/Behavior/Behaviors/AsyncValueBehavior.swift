import Disposable
import Foundation

// MARK: - AsyncValueBehavior

public struct AsyncValueBehavior<Input: Sendable, Output: Sendable>: BehaviorType, Sendable {

  // MARK: Lifecycle

  public init(
    id: BehaviorID,
    _ action: @escaping @Sendable (Input) async -> Output
  ) {
    self.id = id
    self.action = action
    self.runner = RunnerActor(id: id)
  }

  // MARK: Public
  public typealias Handler = AsyncValueHandler<Output>
  public typealias Action = @Sendable (Input) async -> Output
  public let id: BehaviorID

  // MARK: Private

  private let runner: RunnerActor
  public let action: @Sendable (Input) async -> Output

}

// MARK: - Public API
extension AsyncValueBehavior {
  /// - Parameters:
  ///   - onFinish: A callback run when the behavior completes returning a value.
  ///   - onCancel: A callback run if the behavior is cancelled because its hosting ``Node`` is
  /// deactivated.
  public func onFinish(
    _ onFinish: @escaping @Sendable @TreeActor (_ value: Output) -> Void,
    onCancel: @escaping @Sendable @TreeActor () -> Void = { }
  ) {
    subscribe(handler: AsyncValueHandler<Output>(onValue: onFinish, onCancel: onCancel))
  }

  public func subscribe(handler: AsyncValueHandler<Output>) {
    Task {
      await runner.subscribe(handler: handler)
    }
  }
}

// MARK: - AsyncValueHandler

public struct AsyncValueHandler<Output>: BehaviorHandler, Sendable {
  public typealias Failure = Never
  public init(
    onValue: @escaping @Sendable @TreeActor (_ value: Output) -> Void,
    onCancel: @escaping @Sendable @TreeActor () -> Void = { }
  ) {
    self.onValue = onValue
    self.onCancel = onCancel
  }

  let onValue: @Sendable @TreeActor (_ value: Output) -> Void
  let onCancel: @Sendable @TreeActor () -> Void
}

// MARK: - Internal API
extension AsyncValueBehavior {

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

// MARK: - AsyncValueBehavior.RunnerActor

extension AsyncValueBehavior {
  private actor RunnerActor {

    // MARK: Lifecycle

    init(id: BehaviorID) {
      self.id = id
    }

    // MARK: Internal

    let id: BehaviorID
    let resolution = AsyncValue<BehaviorResolution>()

    func run(action: @escaping @Sendable (Input) async -> Output, input: Input) async -> Bool {
      lifeState.start(handle: {
        Task {
          await withTaskCancellationHandler {
            let value = await action(input)
            self.finish(value: value)
          } onCancel: {
            Task {
              await self.cancel()
            }
          }
        }
      })
    }

    func subscribe(handler: AsyncValueHandler<Output>) {
      switch lifeState {
      case .running,
           .unstarted:
        handlers.append(handler)
      case .cancelled:
        Task { @TreeActor [handler] in
          handler.onCancel()
        }
      case .finished(let result):
        Task { @TreeActor [handler, result] in
          handler.onValue(result)
        }
      }
    }

    func cancel() {
      if let resolution = lifeState.cancel(id: id) {
        let handlers = handlers
        self.handlers = []
        Task { @TreeActor [handlers] in
          for handler in handlers {
            handler.onCancel()
          }
          await self.resolution.resolve(resolution)
        }
      }
    }

    // MARK: Private

    private var lifeState: LifeState = .unstarted

    private var handlers: [AsyncValueHandler<Output>] = []

    private func finish(value: Output) {
      if let resolution = lifeState.finish(id: id, result: value) {
        let handlers = handlers
        self.handlers = []
        Task { @TreeActor [handlers] in
          for handler in handlers {
            handler.onValue(value)
          }
          await self.resolution.resolve(resolution)
        }
      }
    }

  }
}

// MARK: - AsyncValueBehavior.LifeState

extension AsyncValueBehavior {

  private enum LifeState {
    case unstarted
    case running(handle: Task<Void, Never>, startTime: Double)
    case finished(output: Output)
    case cancelled

    // MARK: Internal

    mutating func start(handle: () -> Task<Void, Never>) -> Bool {
      switch self {
      case .cancelled,
           .finished,
           .running:
        return false
      case .unstarted:
        self = .running(handle: handle(), startTime: ProcessInfo.processInfo.systemUptime)
        return true
      }
    }

    mutating func finish(id: BehaviorID, result: Output) -> BehaviorResolution? {
      switch self {
      case .cancelled,
           .finished:
        return nil
      case .unstarted:
        self = .finished(output: result)
        return BehaviorResolution(
          id: id,
          resolution: .finished,
          startTime: nil,
          endTime: ProcessInfo.processInfo.systemUptime
        )
      case .running(let handle, let startTime):
        handle.cancel()
        self = .finished(output: result)
        return BehaviorResolution(
          id: id,
          resolution: .finished,
          startTime: startTime,
          endTime: ProcessInfo.processInfo.systemUptime
        )
      }
    }

    mutating func cancel(id: BehaviorID) -> BehaviorResolution? {
      switch self {
      case .cancelled,
           .finished:
        return nil
      case .running(let handle, let startTime):
        handle.cancel()
        self = .cancelled
        return BehaviorResolution(
          id: id,
          resolution: .cancelled,
          startTime: startTime,
          endTime: ProcessInfo.processInfo.systemUptime
        )
      case .unstarted:
        self = .cancelled
        return .init(
          id: id,
          resolution: .cancelled,
          startTime: 0,
          endTime: ProcessInfo.processInfo.systemUptime
        )
      }
    }
  }
}
