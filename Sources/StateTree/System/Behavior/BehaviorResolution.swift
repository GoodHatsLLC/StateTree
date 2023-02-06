// MARK: - BehaviorResolution

public struct BehaviorResolution {
  public enum Resolution {
    case cancelled
    case failed
    case finished
  }

  public let id: BehaviorID
  public let resolution: Resolution
  let startTime: Double?
  let endTime: Double
  public var executionTime: Double {
    (startTime ?? endTime) - endTime
  }
}
