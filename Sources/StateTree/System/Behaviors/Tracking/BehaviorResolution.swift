import Emitter
// MARK: - BehaviorResolution

extension Behaviors {

  public struct Resolution: Sendable, Hashable {
    public static func == (lhs: Behaviors.Resolution, rhs: Behaviors.Resolution) -> Bool {
      lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }

    public let id: BehaviorID
    private let resolution = AsyncValue<Resolved>()
    public func resolve(to state: Resolved.State) {
      resolution.resolve(.init(id: id, state: state))
    }

    public var value: Resolved {
      get async {
        await resolution.value
      }
    }
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
