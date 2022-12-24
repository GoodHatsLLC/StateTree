// MARK: - FailingBehavior

public struct FailingBehavior: Error {
  public init(id: String) {
    self.id = id
  }

  public let id: String
}

extension Behavior {
  public static func fail<V>(_ id: String = "failing-behavior") -> Behavior<V> {
    .init(id) {
      throw FailingBehavior(id: "\(id)")
    }
  }
}
