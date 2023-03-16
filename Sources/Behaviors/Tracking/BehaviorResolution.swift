import Utilities

// MARK: - BehaviorResolution

extension Behaviors {

  public struct Resolution: Sendable, Hashable {

    // MARK: Lifecycle

    init(id: BehaviorID, value: Resolved? = nil) {
      self.id = id
      let res: AsyncValue<Resolved> = if let value {
        .init(value: value)
      } else {
        .init()
      }
      self.resolution = res
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

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }

    public func resolve(to state: Resolved.State, act: @escaping () async -> Void = { }) async {
      await resolution.resolve(.init(id: id, state: state), act: act)
    }

    public func ifMatching(
      _ filter: (_ value: Resolved.State?) -> Bool,
      run act: @escaping () async -> Void
    ) async {
      await resolution.ifMatching({ filter($0?.state) }, run: act)
    }

    // MARK: Internal

    static func cancelled(id: BehaviorID) -> Resolution {
      Self(id: id, value: .init(id: id, state: .cancelled))
    }

    // MARK: Private

    private let resolution: AsyncValue<Resolved>
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
