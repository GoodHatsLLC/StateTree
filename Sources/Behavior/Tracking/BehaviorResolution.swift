import Utilities

// MARK: - BehaviorResolution

extension Behaviors {

  public struct Resolution: Sendable, Hashable {

    // MARK: Lifecycle

    init(
      id: BehaviorID,
      tracker: BehaviorTracker,
      value: Result? = nil
    ) {
      self.id = id
      let res: Async.Value<Result>
      let started: Async.Value<Void>
      let isFinished: Bool
      if let value {
        (res, started) = (Async.Value<Result>(value: value), Async.Value<Void>(value: ()))
        isFinished = true
      } else {
        (res, started) = (.init(), .init())
        isFinished = false
      }
      self.resolution = res
      self.started = started
      let (startedCallback, finishedCallback) = tracker.trackCreate(resolution: self)
      self.startedCallback = startedCallback
      self.finishedCallback = finishedCallback
      if isFinished {
        startedCallback()
        finishedCallback()
      }
    }

    // MARK: Public

    public let id: BehaviorID

    public var value: Result {
      get async {
        await resolution.value
      }
    }

    public static func == (lhs: Behaviors.Resolution, rhs: Behaviors.Resolution) -> Bool {
      lhs.id == rhs.id
    }

    public func awaitReady() async {
      await started.value
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }

    // MARK: Internal

    static func cancelled(id: BehaviorID, tracker: BehaviorTracker) -> Resolution {
      Self(id: id, tracker: tracker, value: .init(id: id, state: .cancelled))
    }

    func markStarted() async {
      await started.resolve {
        startedCallback?()
      }
    }

    func resolve(
      to state: Result.State,
      act: @escaping () async -> Void = { }
    ) async {
      await started.resolve {
        startedCallback?()
      }
      await resolution.resolve(
        to: .init(id: id, state: state)
      ) {
        finishedCallback?()
        await act()
      }
    }

    func ifMatching(
      _ filter: (_ value: Result.State?) -> Bool,
      run act: @escaping () async -> Void
    ) async {
      await resolution.ifMatching({ filter($0?.state) }, action: act)
    }

    // MARK: Private

    private var startedCallback: (@Sendable () -> Void)?
    private var finishedCallback: (@Sendable () -> Void)?

    private let resolution: Async.Value<Result>
    private let started: Async.Value<Void>
  }

  public struct Result: Sendable, Hashable {

    public let id: BehaviorID
    public let state: State

    public enum State: Sendable {
      case cancelled
      case failed
      case finished
    }

  }
}
