import Dependencies
import Utilities

@MainActor
@propertyWrapper
public final class Dependency<Value> {

  public init(_ keyPath: KeyPath<DependencyValues, Value>) {
    do {
      values = try DependencyStack.top
    } catch {
      DependencyValues.defaults.logger.warn(
        message:
          """
          "No DependencyValues are available in this context — the default will always be used
          Note: the @Dependency property wrapper is only available during route(state:) calls —
          and so Model member-field properties which are evaluated during the Model's init
          """
      )
      values = .defaults
    }
    self.keyPath = keyPath
  }

  public var wrappedValue: Value {
    values[keyPath: keyPath]
  }

  var values: DependencyValues
  let keyPath: KeyPath<DependencyValues, Value>

}
