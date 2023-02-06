// MARK: - ProjectionField

protocol ProjectionField<Value> {
  associatedtype Value
  @TreeActor
  func isValid() -> Bool
  var source: ProjectionSource { get }
  var projectionContext: ProjectionConnection? { get nonmutating set }
  @TreeActor var value: Value { get set }
}

// MARK: - ProjectionConnection

struct ProjectionConnection {
  let runtime: Runtime
  let fieldID: FieldID
}

// MARK: - Projection

/// A `Projection` references a value whose source of truth is elsewhere.
///
/// The underlying referenced value is represented by an ``Accessor`` which
/// is back by either:
/// - A ``Value`` owned by a ``Node`` which is an ancestor to the one
///   containing the `Projection`.
/// - Or more rarely a closure capturing a value.
///
/// A `Projection` in StateTree serves the same purpose as a `Binding` in SwiftUI.
/// It allows a parent `Node` to share state with a child.
///
/// > Important: Shared state should have a clear contract. If multiple nodes react to shared
/// state changes in conflicting ways they may create a circular dependency in their combined
/// reaction logic. StateTree will detect and revert the state change triggering the circular
/// dependency—but that's likely to be a costly process with a poor end-user  uexperience.
@propertyWrapper
@dynamicMemberLookup
public struct Projection<Value: TreeState>: ProjectionField, Accessor {

  // MARK: Lifecycle

  @TreeActor
  init(_ access: some Accessor<Value>) {
    self.access = access
    self.inner = Inner(cache: access.value)
  }

  // MARK: Public

  public var value: Value {
    get {
      guard access.isValid()
      else {
        runtimeWarning(
          "The projection accessed was invalid. The last cached value was returned."
        )
        assertionFailure("the projection cache should never be used")
        return inner.cache
      }
      let value = access.value
      inner.cache = value
      return value
    }
    nonmutating set {
      guard access.isValid()
      else {
        runtimeWarning(
          "The projection written to was invalid. The write was discarded."
        )
        assertionFailure("an invalidated projection should never be written to")
        return
      }
      if access.value != newValue {
        registerWriteMetadata()
        access.value = newValue
        inner.cache = newValue
      }
    }
  }

  public var wrappedValue: Value {
    get { value }
    nonmutating set {
      value = newValue
    }
  }

  public var projectedValue: Projection<Value> {
    .init(self)
  }

  // MARK: Internal

  @TreeActor var projectionContext: ProjectionConnection? {
    get { inner.projectionContext }
    nonmutating set { inner.projectionContext = newValue }
  }

  var source: ProjectionSource {
    access.source
  }

  func isValid() -> Bool {
    access.isValid()
  }

  // MARK: Private

  @TreeActor private final class Inner {

    // MARK: Lifecycle

    nonisolated init(cache: Value) {
      self.cache = cache
    }

    // MARK: Internal

    var cache: Value
    var projectionContext: ProjectionConnection?
  }

  private let inner: Inner

  private let access: any Accessor<Value>

  /// Register the projection's metadata with the ``Runtime`` providing
  /// diagnostic information in case of circular update dependencies.
  private func registerWriteMetadata() {
    guard let projectionContext
    else {
      // An intermediate Projection not assigned to a Node field will not
      // have a projectionContext set by StateTree.

      // TODO: Consider weird cases:
      // - projections used directly as instance variables
      // - projections used only within an initialiser.
      return
    }
    projectionContext.runtime
      .register(
        metadata: .init(
          projection: projectionContext.fieldID,
          source: source
        )
      )
  }

}
