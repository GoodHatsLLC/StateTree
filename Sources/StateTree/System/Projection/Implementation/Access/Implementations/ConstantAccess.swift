import TreeActor

/// An `Access` conformer which provides a constant value.
///
/// > Warning: `Access.ConstantAccess` ignores value setter calls.
@TreeActor
struct ConstantAccess<Value>: Accessor {

  init(_ value: Value) {
    self.constant = value
  }

  private let constant: Value
  var source: ProjectionSource { .programmatic }
  var value: Value {
    get { constant }
    nonmutating set { }
  }

  func isValid() -> Bool { true }
}
