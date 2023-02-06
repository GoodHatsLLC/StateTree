// MARK: - DependencyKey

public protocol DependencyKey: Hashable {
  associatedtype Value
  static var defaultValue: Value { get }
}

extension DependencyKey {
  public static var value: Value { defaultValue }
}

extension DependencyKey {
  static var hashable: MetatypeWrapper {
    MetatypeWrapper(metatype: self.self)
  }
}
