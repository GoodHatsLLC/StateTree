import Disposable
import Emitter
import StateTree

// MARK: - Player

public final class Player<Root: Node> {

  // MARK: Lifecycle

  public init(tree: Tree<Root>, frames: [StateFrame]) throws {
    guard
      !frames.isEmpty,
      let initialFrame = frames.first,
      initialFrame.state != nil
    else {
      throw NoFramesPlaybackError()
    }
    self.tree = tree
    self.finalFrameIndex = frames.endIndex - 1
    self.currentFrameIndexSubject = .init(finalFrameIndex)
    self.frames = frames
    self.initialState = initialFrame
  }

  // MARK: Public

  public let frames: [StateFrame]

  public var currentFrameIndexEmitter: some Emitter<Int, Never> { currentFrameIndexSubject }

  @TreeActor public var currentFrame: StateFrame {
    frames[currentFrameIndex]
  }

  public var frameRange: ClosedRange<Int> { 0 ... (frames.count - 1) }
  public var frameRangeDouble: ClosedRange<Double> { 0 ... Double(max(frames.count - 1, 1)) }

  @TreeActor public var currentFrameIndex: Int {
    get { currentFrameIndexSubject.value }
    set {
      if frameRange.contains(newValue) {
        currentFrameIndexSubject.value = newValue
      }
    }
  }

  @TreeActor public var framesToCurrent: [StateFrame] {
    Array(frames[0 ... currentFrameIndex])
  }

  @TreeActor  public var currentStateRecord: StateFrame {
    for i in (0 ..< framesToCurrent.count).reversed() {
      let frame = frames[i]
      if let state = frame.state {
        return .init(data: .update(currentFrame.event, state))
      }
    }
    return initialState
  }

  @discardableResult
  @TreeActor
  public func start() throws -> PlayHandle {
    guard activeHandle == nil
    else {
      throw PlayerAlreadyActiveError()
    }
    guard !frames.isEmpty
    else {
      throw NoFramesPlaybackError()
    }

    let disposable = currentFrameIndexEmitter
      .filter { [frameRange] in frameRange.contains($0) }
      .map { [frames] num in
        frames[num]
      }
      .subscribe { [weak self] _ in
        guard let self
        else {
          return
        }
        do {
          try tree.active { active in
            try active.restore(state: self.currentStateRecord.state!)
          }
        } catch {
          assertionFailure(error.localizedDescription)
        }
      }
    let handle = PlayHandle {
      disposable.dispose()
      self.activeHandle = nil
      return self.framesToCurrent
    }
    activeHandle = handle
    return handle
  }

  @discardableResult
  @TreeActor
  public func stop() throws -> [StateFrame] {
    guard let activeHandle
    else {
      throw PlayerInactiveError()
    }
    return activeHandle.stop()
  }

  @TreeActor
  public func next() -> Int {
    currentFrameIndex += 1
    return currentFrameIndex
  }

  @TreeActor
  public func previous() -> Int {
    currentFrameIndex -= 1
    return currentFrameIndex
  }

  // MARK: Private

  private let initialState: StateFrame

  private let tree: Tree<Root>
  private let finalFrameIndex: Int
  private let currentFrameIndexSubject: ValueSubject<Int, Never>
  private var activeHandle: PlayHandle?
}

// MARK: - NoFramesPlaybackError

struct NoFramesPlaybackError: Error { }

// MARK: - PlayerInactiveError

struct PlayerInactiveError: Error { }

// MARK: - PlayerAlreadyActiveError

struct PlayerAlreadyActiveError: Error { }
