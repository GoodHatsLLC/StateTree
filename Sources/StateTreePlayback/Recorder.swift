import Behavior
import Disposable
import Emitter
import Foundation
import TreeActor
@_spi(Implementation) import StateTree

// MARK: - TreeRecorder

public protocol TreeRecorder: Identifiable, Hashable {
  var id: UUID { get }
  @TreeActor var frames: [StateFrame] { get }
  @discardableResult @TreeActor
  func start() throws -> RecordHandle
  @discardableResult @TreeActor
  func stop() throws -> [StateFrame]
  func erase() -> AnyRecorder
}

extension TreeRecorder {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - Recorder

public final class Recorder<Root: Node>: TreeRecorder {

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

  public let id = UUID()

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
    let runtime = try tree.assume.runtime
    let disposable = tree
      .events
      .treeEventEmitter
      .withPrefix([TreeEvent.recording(event: .started(recorderID: id))])
      .map { events in
        events.filter { event in
          switch event {
          case .behavior(event: let event):
            switch event {
            case .created: return false
            default: return true
            }
          default: return true
          }
        }
      }
      .subscribeMain { events in
        var hasUpdateEvent = false
        for event in events {
          switch event {
          case .node,
               .recording,
               .tree where hasUpdateEvent == false:
            hasUpdateEvent = true
            self.frames.append(
              .init(
                data: .update(
                  event,
                  runtime.snapshot()
                )
              )
            )
          default:
            self.frames.append(
              .init(
                data: .meta(
                  event
                )
              )
            )
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
      return activeHandle.stop() + [.init(
        data: .update(
          TreeEvent.recording(event: .stopped(recorderID: id)),
          try tree.assume.snapshot()
        )
      )]
    } else {
      throw RecorderInactiveError()
    }
  }

  public func erase() -> AnyRecorder {
    AnyRecorder(self)
  }

  // MARK: Private

  private let currentFrameSubject = ValueSubject<StateFrame?, Never>(.none)
  private let frameCountSubject: ValueSubject<Int, Never>
  private let tree: Tree<Root>
  private var activeHandle: RecordHandle?
}

// MARK: - AnyRecorder

public struct AnyRecorder: TreeRecorder {
  public var frames: [StateFrame] {
    underlying.frames
  }

  init(_ recorder: some TreeRecorder) {
    self.id = recorder.id
    self.underlying = recorder
  }

  @discardableResult
  @TreeActor
  public func start() throws -> RecordHandle {
    try underlying.start()
  }

  @discardableResult
  @TreeActor
  public func stop() throws -> [StateFrame] {
    try underlying.stop()
  }

  public func erase() -> AnyRecorder {
    self
  }

  public let id: UUID
  private let underlying: any TreeRecorder
}

// MARK: - RecorderRestartError

struct RecorderRestartError: Error { }

// MARK: - RecorderInactiveError

struct RecorderInactiveError: Error { }

// MARK: - RecorderAlreadyActiveError

struct RecorderAlreadyActiveError: Error { }
