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
    tree: Tree<Root>,
    frames: [StateFrame] = []
  ) {
    self.tree = tree
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

  public var currentFrameEmitter: some Emitter<StateFrame, Never> {
    currentFrameSubject.compactMap { $0 }
  }

  public var frameCountEmitter: some Emitter<Int, Never> {
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
    return tree
      .updates
      .subscribe { [self] event in
        frames
          .append(
            StateFrame(
              record: try! tree.snapshot(),
              event: event
            )
          )
      }
  }

  // MARK: Private

  private let currentFrameSubject = ValueSubject<StateFrame?, Never>(.none)
  private let frameCountSubject = ValueSubject<Int, Never>(0)
  private let stage = DisposableStage()
  private let tree: Tree<Root>
}

// MARK: - RecorderRestartError

struct RecorderRestartError: Error { }
