import Behavior
import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTree

extension BehaviorEvent {
  func asTreeEvent() -> TreeEvent {
    switch self {
    case .created(let id):
      return .behaviorCreated(id)
    case .started(let id):
      return .behaviorStarted(id)
    case .finished(let id):
      return .behaviorFinished(id)
    }
  }
}

// MARK: - Recorder

public final class Recorder<Root: Node> {

  // MARK: Lifecycle

  init(
    lifetime: TreeLifetime<Root>,
    frames: [StateFrame] = []
  ) {
    self.lifetime = lifetime
    self.frames = frames
  }

  // MARK: Public

  @TreeActor public var frameRange: ClosedRange<Int> { 0 ... (frames.count - 1) }
  @TreeActor public var frameRangeDouble: ClosedRange<Double> {
    0 ... Double(max(frames.count - 1, 1))
  }

  @TreeActor public var currentFrame: StateFrame? {
    frames.last
  }

  public var currentFrameEmitter: some Emitter<StateFrame> {
    currentFrameSubject.compactMap { $0 }
  }

  public var frameCountEmitter: some Emitter<Int> {
    frameCountSubject
  }

  @TreeActor public private(set) var frames: [StateFrame] {
    didSet {
      currentFrameSubject.emit(value: frames.last)
      frameCountSubject.emit(value: frames.count)
    }
  }

  @TreeActor
  public func start() throws -> AutoDisposable {
    guard
      lifetime.runtime.info.isActive
    else {
      throw RecorderRestartError()
    }
    return lifetime
      .runtime
      .behaviorEvents
      .map { $0.asTreeEvent() }
      .merge(lifetime.updates)
      .subscribe { [self] event in
        frames
          .append(
            StateFrame(
              record: lifetime.snapshot(),
              event: event
            )
          )
      }
  }

  // MARK: Private

  private let currentFrameSubject = ValueSubject<StateFrame?>(.none)
  private let frameCountSubject = ValueSubject<Int>(0)
  private let stage = DisposableStage()
  private let lifetime: TreeLifetime<Root>
}

// MARK: - RecorderRestartError

struct RecorderRestartError: Error { }
