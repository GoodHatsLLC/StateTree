import Disposable
import Foundation

// MARK: - OwningBehavior

public struct OwningBehavior<Input>: BehaviorType {

  // MARK: Lifecycle

  public init(
    id: BehaviorID,
    _ action: @escaping (Input) -> AnyDisposable
  ) {
    self.id = id
    self.action = action
  }

  public init(
    id: BehaviorID,
    _ action: @escaping (Input) -> some Disposable
  ) {
    self.id = id
    self.action = { action($0).erase() }
  }

  // MARK: Public

  public typealias Output = Void
  public typealias Handler = Never
  public typealias Action = (Input) -> AnyDisposable

  public let id: BehaviorID

  public let action: (Input) -> AnyDisposable

  public func subscribe(handler _: Never) { }

  // MARK: Private

  private let resolution = AsyncValue<BehaviorResolution>()
  private let runner = Runner()

}

// MARK: OwningBehavior.Runner

extension OwningBehavior {
  @TreeActor
  private final class Runner {

    // MARK: Lifecycle

    nonisolated init() { }

    // MARK: Internal

    var state: State = .unstarted
  }
}

// MARK: OwningBehavior.State

extension OwningBehavior {
  private enum State {
    case unstarted
    case started(time: Double, disposable: Disposable)
    case cancelled

    mutating func start(action: (Input) -> Disposable, input: Input) {
      switch self {
      case .unstarted:
        self = .started(time: CFAbsoluteTimeGetCurrent(), disposable: action(input))
      case .cancelled,
           .started:
        break
      }
    }

    mutating func cancel() -> Double? {
      switch self {
      case .cancelled,
           .unstarted:
        return nil
      case .started(let time, let disposable):
        disposable.dispose()
        return time
      }
    }
  }
}

// MARK: - Internal API
extension OwningBehavior {

  public nonisolated func dispose() {
    Task { @TreeActor in
      if let startTime = runner.state.cancel() {
        let endTime = CFAbsoluteTimeGetCurrent()
        await resolution
          .resolve(.init(id: id, resolution: .cancelled, startTime: startTime, endTime: endTime))
      }
    }
  }

  @TreeActor
  public func run(on scope: some Scoping, input: Input) {
    let action = scope.host(behavior: self, input: input) ?? action
    runner.state.start(action: action, input: input)
  }

  public func resolution() async -> BehaviorResolution {
    await resolution.value
  }

}
