/// An ``Accessor`` which stores and provides a `Value`.
final class StoredAccess<Value>: Accessor {

  // MARK: Lifecycle

  nonisolated init(_ value: Value) {
    self.value = value
  }

  // MARK: Internal

  var value: Value

  var source: ProjectionSource { .programmatic }

  func isValid() -> Bool { true }
}
