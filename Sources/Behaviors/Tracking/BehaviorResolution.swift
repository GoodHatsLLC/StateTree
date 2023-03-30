import Utilities

// MARK: - BehaviorResolution

extension Behaviors {

  public struct Resolution: Sendable, Hashable {

    // MARK: Lifecycle

    init(id: BehaviorID, value: Resolved? = nil) {
      self.id = id
      let res: Async.Value<Resolved>
      let started: Async.Value<Void>
      if let value {
        (res, started) = (Async.Value<Resolved>(value: value), Async.Value<Void>(value: ()))
      } else {
        (res, started) = (.init(), .init())
      }
      self.resolution = res
      self.started = started
    }

    // MARK: Public

    public let id: BehaviorID

    public var value: Resolved {
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

    static func cancelled(id: BehaviorID) -> Resolution {
      Self(id: id, value: .init(id: id, state: .cancelled))
    }

    func markStarted() async {
      await started.resolve(())
    }

    func resolve(to state: Resolved.State, act: @escaping () async -> Void = { }) async {
      await started.resolve(())
      await resolution.resolve(.init(id: id, state: state), act: act)
    }

    func ifMatching(
      _ filter: (_ value: Resolved.State?) -> Bool,
      run act: @escaping () async -> Void
    ) async {
      await resolution.ifMatching({ filter($0?.state) }, run: act)
    }

    // MARK: Private

    private let resolution: Async.Value<Resolved>
    private let started: Async.Value<Void>
  }

  public struct Resolved: Sendable, Hashable {

    public let id: BehaviorID
    public let state: State

    public enum State: Sendable {
      case cancelled
      case failed
      case finished
    }

  }
}
