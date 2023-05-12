/// An ``Access`` conformer which captures its source.
struct CapturedAccess<Value>: Accessor {

  nonisolated init(
    getter: @escaping () -> Value,
    setter: @escaping (_ value: Value) -> Void,
    isValid: @escaping () -> Bool = { true }
  ) {
    self.getterFunc = getter
    self.setterFunc = setter
    self.isValidFunc = isValid
  }

  var source: ProjectionSource { .programmatic }

  var value: Value {
    get { getterFunc() }
    nonmutating set { setterFunc(newValue) }
  }

  func isValid() -> Bool { isValidFunc() }

  private let getterFunc: () -> Value
  private let setterFunc: (Value) -> Void
  private let isValidFunc: () -> Bool

}
