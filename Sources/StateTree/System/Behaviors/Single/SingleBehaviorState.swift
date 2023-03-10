import Emitter
import Foundation

// MARK: - SingleBehaviorState

public actor SingleBehaviorState<Value: Sendable, Failure: Error>: BehaviorStateType {

  // MARK: Lifecycle

  public init(resolution: Behaviors.Resolution) {
    self.id = resolution.id
    self.state = .running(
      startTime: ProcessInfo.processInfo.systemUptime
    )
    self.resolution = resolution
  }

  // MARK: Public

  public typealias Event = BehaviorEvents.Single<Value, Failure>

  public let id: BehaviorID
  public let resolution: Behaviors.Resolution

  public func update(
    handler: Behaviors.Handler<BehaviorEvents.Single<Value, Failure>>,
    with event: BehaviorEvents.Single<Value, Failure>
  ) {
    Task {
      switch (state, event) {
      case (.cancelled, _):
        break
      case (.finished, _):
        break
      case (.running, .cancelled):
        state = .cancelled
        await handler.send(event: event)
        resolution.resolve(to: .cancelled)
      case (.running(let startTime), .failed(let error)):
        state = .finished(
          result: .failure(error),
          runTime: ProcessInfo.processInfo.systemUptime - startTime
        )
        await handler.send(event: event)
        resolution.resolve(to: .failed)
      case (.running(let startTime), .finished(let value)):
        state = .finished(
          result: .success(value),
          runTime: ProcessInfo.processInfo.systemUptime - startTime
        )
        await handler.send(event: event)
        resolution.resolve(to: .finished)
      }
    }
  }

  // MARK: Private

  private enum State {
    case running(startTime: Double)
    case finished(result: Result<Value, Failure>, runTime: Double)
    case cancelled
  }

  private var state: State
}
