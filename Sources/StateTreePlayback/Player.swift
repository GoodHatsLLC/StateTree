import Disposable
import Emitter
import StateTree

// MARK: - Player

public final class Player<Root: Node>: Disposable {

  // MARK: Lifecycle

  init(lifetime: TreeLifetime<Root>, frames: [StateFrame]) throws {
    guard !frames.isEmpty
    else {
      throw NoFramesPlaybackError()
    }
    self.finalFrame = frames.endIndex - 1
    self.current = .init(finalFrame)
    self.lifetime = lifetime
    self.frames = frames
  }

  // MARK: Public

  public let frames: [StateFrame]

  public var currentFrameIndex: some Emitter<Int> { current }

  public var currentFrame: StateFrame {
    frames[current.value]
  }

  public var frameRange: ClosedRange<Int> { 0 ... (frames.count - 1) }
  public var frameRangeDouble: ClosedRange<Double> { 0 ... Double(max(frames.count - 1, 1)) }

  @TreeActor public var frame: Int {
    get { current.value }
    set {
      if frameRange.contains(newValue) {
        current.value = newValue
      }
    }
  }

  public var isDisposed: Bool {
    stage.isDisposed
  }

  @TreeActor
  public func start() throws {
    guard !frames.isEmpty
    else {
      throw NoFramesPlaybackError()
    }

    current
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
      .stage(on: stage)
  }

  public func stop() -> [StateFrame] {
    stage.dispose()
    return Array(frames[0 ... current.value])
  }

  public func dispose() {
    stage.dispose()
  }

  @TreeActor
  public func next() -> Int {
    frame += 1
    return frame
  }

  @TreeActor
  public func previous() -> Int {
    frame -= 1
    return frame
  }

  // MARK: Private

  private let lifetime: TreeLifetime<Root>
  private let finalFrame: Int
  private let current: ValueSubject<Int>
  private let stage = DisposableStage()
}

// MARK: - NoFramesPlaybackError

struct NoFramesPlaybackError: Error { }
