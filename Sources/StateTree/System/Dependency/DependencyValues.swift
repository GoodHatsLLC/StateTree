/// A source struct for injecting dependencies into nodes.
///
/// The `Dependency` system is modeled after SwiftUI's `Environment`.
/// DependencyValues are added by extending `DependencyValues`
/// with a field accessed via a `DependencyKey` self 'metatype'.
///
/// ``` swift
/// public struct MyNetworkManager { /* ... */ }
///
/// // A DependencyKey conformance must implement defaultValue
/// extension SomeNetworkManager: DependencyKey {
///   static var defaultValue: MyNetworkManager { MyNetworkManager(config: .mock) }
/// }
///
/// // To be injected a dependency must be given a referenceable name
/// extension DependencyValues {
///   var networkManager: MyNetworkManager {
///     get { self[MyNetworkManager.self] }
///     set { self[MyNetworkManager.self] = newValue }
///   }
/// }
/// ```
///
///
/// The value can then be accessed within nodes using the ``Dependency`` property wrapper.
/// ```swift
/// @Dependency(\.networkManager) var networkManager
/// ```
///
/// Dependencies can also be updated for all consumers within a ``Node``'s subtree while routing
/// from the node's rules section.
/// ```swift
/// $someRoute
///   .serve {
///     SomeNode()
///   }
///   .injecting {
///     $0.networkManager = SomeNetworkManager(config: .prod)
///   }
/// ```
///
/// A dependency key can also by implemented with a type unrelated to the payload itself.
/// ```swift
/// public protocol NetworkManagerProtocol { /* ... */ }
/// struct MockNetworkManager: NetworkManagerProtocol { /* ... */ }
/// struct ProductionNetworkManager: NetworkManagerProtocol { /* ... */ }
///
/// struct NetworkManagerKey: DependencyKey {
///     static var defaultValue: any NetworkManagerProtocol { MockNetworkManager() }
/// }
/// extension DependencyValues {
///   var networkManager: MyNetworkManager {
///     get { self[NetworkManagerKey.self] }
///     set { self[NetworkManagerKey.self] = newValue }
///   }
/// }
///
/// /* ... */
///
/// // inside a Node's rules.
/// $someRoute
///   .serve {
///     SomeNode()
///   }
///   .injecting {
///     $0.networkManager = ProductionNetworkManager()
///   }
///
/// ```
public struct DependencyValues {

  // MARK: Public

  public static let defaults: DependencyValues = .init()

  @_spi(Internal)
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

  @_spi(Internal)
  public func injecting(modifier: (inout DependencyValues) -> Void)
    -> DependencyValues
  {
    var copy = self
    modifier(&copy)
    return copy
  }

  @discardableResult
  @_spi(Internal)
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
