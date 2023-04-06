import Disposable
import Emitter
import StateTree

// MARK: - Player

public final class Player<Root: Node> {

  // MARK: Lifecycle

  init(lifetime: TreeLifetime<Root>, frames: [StateFrame]) throws {
    guard !frames.isEmpty
    else {
      throw NoFramesPlaybackError()
    }
    self.lifetime = lifetime
    self.finalFrameIndex = frames.endIndex - 1
    self.currentFrameIndexSubject = .init(finalFrameIndex)
    self.frames = frames
  }

  // MARK: Public

  public let frames: [StateFrame]

  public var currentFrameIndexEmitter: some Emitter<Int> { currentFrameIndexSubject }

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

  @TreeActor
  public func start() throws -> AutoDisposable {
    guard !frames.isEmpty
    else {
      throw NoFramesPlaybackError()
    }

    return currentFrameIndexEmitter
      .filter { [frameRange] in frameRange.contains($0) }
      .map { [frames] num in
        frames[num]
      }
      .subscribe { [weak self] frame in
        guard let self
        else {
          return
        }
        do {
          try lifetime.set(state: frame.state)
        } catch {
          assertionFailure(error.localizedDescription)
        }
      }
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

  private let lifetime: TreeLifetime<Root>
  private let finalFrameIndex: Int
  private let currentFrameIndexSubject: ValueSubject<Int>
  private let stage = DisposableStage()
}

// MARK: - NoFramesPlaybackError

struct NoFramesPlaybackError: Error { }
