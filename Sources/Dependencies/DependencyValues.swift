/// A source struct for injecting dependencies into models.
///
/// The `Dependency` system is modelled after SwiftUI's `Environment`.
/// DependencyValues can be added by extending `DependencyValues`
/// with a field which subsfripts `self` with a `DependencyKey` conforrming metatype.
///
/// ``` swift
/// private struct MyDependencyKey: DependencyKey {
///     static let defaultValue: String = "Default value"
/// }
///
/// extension DependencyValues {
///     var myCustomValue: String { self[MyDependencyKey.self] } }
/// }
/// ```
public struct DependencyValues {

  public static let defaults: DependencyValues = .init()

  public func inserting<Value>(
    _ keyPath: WritableKeyPath<DependencyValues, Value>,
    value: Value
  )
    -> DependencyValues
  {
    var copy = self
    copy[keyPath: keyPath] = value
    return copy
  }

  public subscript<Key: DependencyKey>(_: Key.Type) -> Key.Value {
    get { values[Key.hashable] as? Key.Value ?? Key.defaultValue }
    set {
      values[Key.hashable] = newValue
    }
  }

  private(set) var values: [AnyHashable: Any] = [:]

}
