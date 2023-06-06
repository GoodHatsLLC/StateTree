import TreeActor

// MARK: - DependencyField

protocol DependencyField {
  var inner: DependencyInner { get }
}

// MARK: - Dependency

@propertyWrapper
public struct Dependency<Value>: DependencyField {

  public init(_ keyPath: KeyPath<DependencyValues, Value>) {
    self.keyPath = keyPath
  }

  @TreeActor public var wrappedValue: Value {
    values[keyPath: keyPath]
  }

  @TreeActor var values: DependencyValues {
    inner.dependencies
  }

  let keyPath: KeyPath<DependencyValues, Value>

  let inner = DependencyInner()

}

// MARK: - DependencyInner

@TreeActor
final class DependencyInner {

  // MARK: Lifecycle

  nonisolated init() { }

  // MARK: Internal

  var dependencies: DependencyValues = .defaults
}
