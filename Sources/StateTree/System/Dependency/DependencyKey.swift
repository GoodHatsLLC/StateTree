// MARK: - DependencyKey

/// The type conformed to to provide a 'key' for an injected dependency registered with
/// ``DependencyValues``.
public protocol DependencyKey: Hashable {
  associatedtype Value
  static var defaultValue: Value { get }
}

extension DependencyKey {
  static var hashable: MetatypeWrapper {
    MetatypeWrapper(metatype: self.self)
  }
}
