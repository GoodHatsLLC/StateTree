// MARK: - BehaviorCancelled

public struct BehaviorCancelled: Error {
  public init(id: String) {
    self.id = id
  }

  public let id: String
}
