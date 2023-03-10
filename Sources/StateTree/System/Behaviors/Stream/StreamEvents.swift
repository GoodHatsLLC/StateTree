// MARK: - BehaviorStreamEventType

public protocol BehaviorStreamEventType: BehaviorEventType where Success == Never,
  Failure == Error
{
  var concrete: BehaviorEvents.Stream<Output> { get }
  static func errorEvent(error: any Error) -> Self
}

extension BehaviorStreamEventType {
  public var value: Output? {
    get throws {
      switch concrete {
      case .cancelled: throw BehaviorCancellationError()
      case .emission(let output): return output
      case .failed(let error): throw error
      case .finished: return nil
      }
    }
  }
}

// MARK: - BehaviorEvents.Stream

extension BehaviorEvents {
  public enum Stream<Output: Sendable>: BehaviorStreamEventType {
    public typealias Success = Never
    case emission(Output)
    case finished
    case cancelled
    case failed(Failure)

    public static func errorEvent(error: Error) -> BehaviorEvents.Stream<Output> {
      .failed(error)
    }

    public var isCancellation: Bool {
      switch self {
      case .cancelled:
        return true
      case .emission,
           .failed,
           .finished:
        return false
      }
    }

    public var concrete: BehaviorEvents.Stream<Output> { self }
    public static var cancelledEvent: Self { .cancelled }
  }
}
