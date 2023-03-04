public final class Ref<T>: @unchecked Sendable {

  // MARK: Lifecycle

  public init(value: T) {
    self.value = value
  }

  // MARK: Public

  public var value: T
}
