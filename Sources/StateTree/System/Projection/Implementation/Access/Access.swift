import TreeActor

// MARK: - Accessor

/// An `Accessor` provides some opaque access to an underlying ``Value`` or ``Projection``.
@TreeActor
public protocol Accessor<WrappedValue> {
  associatedtype WrappedValue
  @_spi(Implementation) var value: WrappedValue { get nonmutating set }
  @_spi(Implementation)
  func isValid() -> Bool
  @_spi(Implementation) var source: ProjectionSource { get }
}
