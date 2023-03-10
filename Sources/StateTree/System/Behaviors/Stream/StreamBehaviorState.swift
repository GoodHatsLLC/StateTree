import Emitter
import Foundation

// MARK: - StreamBehaviorState

public actor StreamBehaviorState<Output: Sendable, Failure: Error>: BehaviorStateType {

  // MARK: Lifecycle

  public init(resolution: Behaviors.Resolution) {
    self.id = resolution.id
    self.state = .running(
      startTime: ProcessInfo.processInfo.systemUptime
    )
    self.resolution = resolution
  }

  // MARK: Public

  public typealias Event = BehaviorEvents.Stream<Output>

  public let id: BehaviorID
  public let resolution: Behaviors.Resolution

  public func update(
    handler: Behaviors.Handler<BehaviorEvents.Stream<Output>>,
    with event: BehaviorEvents.Stream<Output>
  ) {
    let event = event
    Task {
      switch (state, event) {
      case (.cancelled, _):
        break
      case (.finished, _):
        break
      case (.failure, _):
        break
      case (.running, .emission):
        await handler.send(event: event)
      case (.running, .cancelled):
        state = .cancelled
        await handler.send(event: event)
        resolution.resolve(to: .cancelled)
      case (.running(let startTime), .failed(let error)):
        state = .failure(error: error, runTime: ProcessInfo.processInfo.systemUptime - startTime)
        await handler.send(event: event)
        resolution.resolve(to: .failed)
      case (.running(let startTime), .finished):
        state = .finished(runTime: ProcessInfo.processInfo.systemUptime - startTime)
        await handler.send(event: event)
        resolution.resolve(to: .finished)
      }
    }
  }

  // MARK: Private

  private enum State {
    case running(startTime: Double)
    case finished(runTime: Double)
    case failure(error: Error, runTime: Double)
    case cancelled
  }

  private var state: State
}
