/// A source struct for injecting dependencies into nodes.
///
/// The `Dependency` system is nodeled after SwiftUI's `Environment`.
/// DependencyValues can be added by extending `DependencyValues`
/// with a field which subscripts `self` with a `DependencyKey` conforming metatype.
///
/// ``` swift
/// private struct MyDependencyKey: DependencyKey {
///   static let defaultValue: String = "Default value"
/// }
///
/// extension DependencyValues {
///   var myCustomValue: String {
///     get { self[MyDependencyKey.self] }
///     set { self[MyDependencyKey.self] = newValue }
///   }
/// }
/// ```
public struct DependencyValues {

  // MARK: Public

  public static let defaults: DependencyValues = .init()

  public func injecting<Value>(
    _ keyPath: WritableKeyPath<DependencyValues, Value>,
    value: Value
  )
    -> DependencyValues
  {
    var copy = self
    copy[keyPath: keyPath] = value
    return copy
  }

  @discardableResult
  public mutating func inject<Value>(
    _ keyPath: WritableKeyPath<DependencyValues, Value>,
    value: Value
  )
    -> DependencyValues
  {
    self[keyPath: keyPath] = value
    return self
  }

  public subscript<Key: DependencyKey>(_: Key.Type) -> Key.Value {
    get { values[Key.hashable] as? Key.Value ?? Key.defaultValue }
    set {
      values[Key.hashable] = newValue
    }
  }

  // MARK: Internal

  private(set) var values: [AnyHashable: Any] = [:]

}
