// MARK: - Accessor

/// An `Accessor` provides some opaque access to an underlying `Value`.
///
/// An `Access` should allow a consumer to check its validity prior to use.
@TreeActor
protocol Accessor<WrappedValue> {
  associatedtype WrappedValue
  var value: WrappedValue { get nonmutating set }
  func isValid() -> Bool
  var source: ProjectionSource { get }
}
