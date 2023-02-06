/// An erased ``Access`` conformer.
struct AnyAccess<Value>: Accessor {

  init(_ access: some Accessor<Value>) {
    self.getterFunc = { access.value }
    self.setterFunc = { access.value = $0 }
    self.isValidFunc = { access.isValid() }
    self.sourceTypeFunc = { access.source }
  }

  init(_ access: AnyAccess<Value>) {
    self = access
  }

  var source: ProjectionSource { sourceTypeFunc() }

  var value: Value {
    get { getterFunc() }
    nonmutating set { setterFunc(newValue) }
  }

  func isValid() -> Bool { isValidFunc() }
  func erase() -> AnyAccess<Value> { self }

  private let getterFunc: () -> Value
  private let setterFunc: (Value) -> Void
  private let isValidFunc: () -> Bool
  private let sourceTypeFunc: () -> ProjectionSource

}
