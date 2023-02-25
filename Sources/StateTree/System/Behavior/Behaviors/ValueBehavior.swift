import Disposable
import Foundation

// MARK: - ValueBehavior

public struct ValueBehavior<Input, Output>: BehaviorType {
  public typealias Handler = ValueHandler<Output>

  // MARK: Lifecycle

  public init(
    id: BehaviorID,
    _ action: @escaping @Sendable @TreeActor (Input) -> Output
  ) {
    self.id = id
    self.action = action
  }

  // MARK: Public
  public typealias Action = @TreeActor (Input) -> Output
  public let id: BehaviorID

  // MARK: Private

  public let action: @Sendable @TreeActor (Input) -> Output
  private let resolution = AsyncValue<BehaviorResolution>()
  private let runner = Runner()

}

// MARK: ValueBehavior.Runner

extension ValueBehavior {

  @TreeActor
  private final class Runner {

    // MARK: Lifecycle

    nonisolated init() { }

    // MARK: Internal

    var state: State = .unstarted
    var handlers: [ValueHandler<Output>] = []

    func run(_ act: (Input) -> Output, input: Input) {
      if let result = state.run(action: act, input: input) {
        let handlers = handlers
        self.handlers = []
        Task { @TreeActor in
          for handler in handlers {
            handler.onValue(result)
          }
        }
      }
    }

    func cancel(_: () -> Void) {
      if state.cancel() {
        let handlers = handlers
        self.handlers = []
        Task { @TreeActor in
          for handler in handlers {
            handler.onCancel()
          }
        }
      }
    }

    func subscribe(handler: ValueHandler<Output>) {
      switch state {
      case .unstarted:
        handlers.append(handler)
      case .finished(let t):
        Task { @TreeActor in
          handler.onValue(t)
        }
      case .cancelled:
        Task { @TreeActor in
          handler.onCancel()
        }
      }
    }
  }
}

// MARK: - ValueHandler

public struct ValueHandler<Output>: BehaviorHandler, Sendable {
  public typealias Failure = Never
  let onValue: @TreeActor @Sendable (_ value: Output) -> Void
  let onCancel: @TreeActor @Sendable () -> Void
}

// MARK: - ValueBehavior.State

extension ValueBehavior {

  @TreeActor
  private enum State {
    case unstarted
    case finished(Output)
    case cancelled

    mutating func run(action: @TreeActor (Input) -> Output, input: Input) -> Output? {
      switch self {
      case .unstarted:
        let value = action(input)
        self = .finished(value)
        return value
      case .cancelled,
           .finished:
        return nil
      }
    }

    mutating func cancel() -> Bool {
      switch self {
      case .unstarted:
        self = .cancelled
        return true
      case _:
        return false
      }
    }
  }
}

// MARK: - Internal API
extension ValueBehavior {

  public func subscribe(handler: ValueHandler<Output>) {
    Task {
      await runner.subscribe(handler: handler)
    }
  }

  public nonisolated func dispose() {
    Task { @TreeActor in
      if runner.state.cancel() {
        let time = CFAbsoluteTimeGetCurrent()
        await resolution
          .resolve(.init(id: id, resolution: .cancelled, startTime: nil, endTime: time))
      }
    }
  }

  @TreeActor
  public func run(on scope: some Scoping, input: Input) {
    let action = scope.host(behavior: self, input: input) ?? action
    if nil != runner.state.run(action: action, input: input) {
      let time = CFAbsoluteTimeGetCurrent()
      Task {
        await resolution
          .resolve(.init(id: id, resolution: .finished, startTime: time, endTime: time))
      }
    }
  }

  public func resolution() async -> BehaviorResolution {
    await resolution.value
  }

}
