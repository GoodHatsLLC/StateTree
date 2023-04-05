import Behaviors
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
    frameCountSubject.value = frames.count
  }

  // MARK: Public

  public var frameRange: ClosedRange<Int> { 0 ... (frames.count - 1) }
  public var frameRangeDouble: ClosedRange<Double> { 0 ... Double(max(frames.count - 1, 1)) }

  @TreeActor public var frame: Int {
    frameCountSubject.value
  }

  public var frameCount: some Emitter<Int> { frameCountSubject }

  public var currentFrame: StateFrame? {
    frames.last
  }

  @TreeActor
  public func start() throws {
    guard
      lifetime.runtime.info.isActive
    else {
      throw RecorderRestartError()
    }
    if frames.isEmpty {
      frames
        .append(
          StateFrame(
            record: lifetime.snapshot(),
            event: .treeStarted
          )
        )
    }
    lifetime
      .updates
      .subscribe { [weak self] event in
        if let self {
          frames
            .append(
              StateFrame(
                record: lifetime.snapshot(),
                event: event
              )
            )
        }
      }
      .stage(on: stage)
    lifetime
      .runtime
      .behaviorEvents
      .map { $0.asTreeEvent() }
      .merge(lifetime.updates) // TODO: fix union API
      .subscribe { [weak self] event in
        if let self {
          frames
            .append(
              StateFrame(
                record: lifetime.snapshot(),
                event: event
              )
            )
        }
      }
      .stage(on: stage)
  }

  @TreeActor
  public func stop() throws -> [StateFrame] {
    stage.dispose()
    return frames
  }

  // MARK: Private

  private let frameCountSubject = ValueSubject<Int>(0)

  private let stage = DisposableStage()

  private let lifetime: TreeLifetime<Root>

  private var frames: [StateFrame] {
    didSet {
      frameCountSubject.value = frames.count
    }
  }
}

// MARK: - RecorderRestartError

struct RecorderRestartError: Error { }
