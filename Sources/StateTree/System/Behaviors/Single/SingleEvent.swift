// MARK: - BehaviorSingleEventType

public protocol BehaviorSingleEventType: BehaviorEventType where Output == Never {
  var concrete: BehaviorEvents.Single<Success, Failure> { get }
}

extension BehaviorSingleEventType {
  public var value: Success {
    get throws {
      switch concrete {
      case .finished(let success):
        return success
      case .cancelled:
        throw BehaviorCancellationError()
      case .failed(let error):
        throw error
      }
    }
  }
}

// MARK: - BehaviorEvents.Single

extension BehaviorEvents {

  public enum Single<Success: Sendable, Failure: Error>: BehaviorSingleEventType {
    public typealias Output = Never
    case finished(Success)
    case cancelled
    case failed(Failure)
    public var isCancellation: Bool {
      switch self {
      case .cancelled:
        return true
      case .failed,
           .finished:
        return false
      }
    }

    public static var cancelledEvent: Self { .cancelled }
    public var concrete: BehaviorEvents.Single<Success, Failure> { self }
  }
}
