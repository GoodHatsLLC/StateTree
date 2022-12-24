import Dependencies
import ModelInterface
import Utilities

// MARK: - StoreValue

@MainActor
@propertyWrapper
public struct StoreValue<Value: ModelState> {

  public init(projectedValue: StoreValueAccess<Value>) {
    self.projectedValue = projectedValue
  }

  public let projectedValue: StoreValueAccess<Value>

  public var wrappedValue: Value {
    get {
      projectedValue.getter()
    }
    nonmutating set {
      projectedValue.setter(newValue)
    }
  }

}

// MARK: - StoreValueAccess

@MainActor
public struct StoreValueAccess<Value: ModelState> {

  init<M: Model>(
    _ storage: _ModelStorage<M>,
    path: WritableKeyPath<M.State, Value>
  ) {
    getter = {
      storage.read(path)
    }
    setter = { newValue in
      storage.write { $0[keyPath: path] = newValue }
    }
  }

  let getter: () -> Value
  let setter: (Value) -> Void

}
