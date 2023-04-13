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

  public init(
    tree: Tree<Root>,
    frames: [StateFrame] = []
  ) {
    self.tree = tree
    self.frames = frames
    self.frameCountSubject = ValueSubject<Int, Never>(frames.count)
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

  @discardableResult
  @TreeActor
  public func start() throws -> RecordHandle {
    guard activeHandle == nil
    else {
      throw RecorderAlreadyActiveError()
    }
    let prefix = frames.isEmpty ? [TreeEvent.recordingStarted] : []
    let disposable = tree
      .events
      .treeEventEmitter
      .withPrefix(prefix)
      .subscribeMain { event in
        switch event.category {
        case .metadata:
          self.frames.append(
            .init(
              data: .meta(event)
            )
          )
        case .update:
          do {
            self.frames.append(
              .init(
                data: .update(
                  event,
                  try self.tree.assume.snapshot()
                )
              )
            )
          } catch {
            assertionFailure(error.localizedDescription)
          }
        }
      }
    let handle = RecordHandle(stopFunc: {
      disposable.dispose()
      self.activeHandle = nil
      return self.frames
    })
    activeHandle = handle
    return handle
  }

  @discardableResult
  @TreeActor
  public func stop() throws -> [StateFrame] {
    if let activeHandle {
      return activeHandle.stop()
    } else {
      throw RecorderInactiveError()
    }
  }

  // MARK: Private

  private let currentFrameSubject = ValueSubject<StateFrame?, Never>(.none)
  private let frameCountSubject: ValueSubject<Int, Never>
  private let tree: Tree<Root>
  private var activeHandle: RecordHandle?
}

// MARK: - RecorderRestartError

struct RecorderRestartError: Error { }

// MARK: - RecorderInactiveError

struct RecorderInactiveError: Error { }

// MARK: - RecorderAlreadyActiveError

struct RecorderAlreadyActiveError: Error { }
