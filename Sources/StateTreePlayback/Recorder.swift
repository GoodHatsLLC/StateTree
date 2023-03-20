import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTree

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

  public var frameCount: some Emitting<Int> { frameCountSubject }

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
            record: lifetime.snapshot()
          )
        )
    }
    lifetime
      .updates
      .flatMapLatest { [lifetime] _ in lifetime.stateFrameSnapshot() }
      .subscribe { [weak self] snapshot in
        if let self {
          frames
            .append(snapshot)
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
