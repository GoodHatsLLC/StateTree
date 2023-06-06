import TreeActor
import Utilities

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
/// The underlying referenced value is backed by either:
/// - A ``Value`` owned by a ``Node`` which is an ancestor to the one
///   containing the `Projection`.
/// - Or more rarely a closure capturing a value.
///
/// A `Projection` in StateTree serves the same purpose as a `Binding` in SwiftUI.
/// It allows a parent `Node` to share state with a child.
///
/// > Important: Shared state should have a clear contract. If multiple nodes react to shared
/// state changes in conflicting ways they may create a circular dependency in their combined
/// reaction logic.
@propertyWrapper
@dynamicMemberLookup
public struct Projection<Value: Equatable>: ProjectionField, Accessor {

  // MARK: Lifecycle

  public nonisolated init(_ access: some Accessor<Value>, initial: Value) {
    self.access = access
    self.inner = Inner(cache: initial)
  }

  // MARK: Public

  public var value: Value {
    get {
      guard access.isValid()
      else {
        runtimeWarning(
          "The projection accessed was invalid. The last cached value was returned."
        )
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
        return
      }
      if access.value != newValue {
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

  @_disfavoredOverload public var projectedValue: Projection<Value> {
    .init(self, initial: value)
  }

  public var source: ProjectionSource {
    access.source
  }

  public func isValid() -> Bool {
    access.isValid()
  }

  // MARK: Internal

  @TreeActor var projectionContext: ProjectionConnection? {
    get { inner.projectionContext }
    nonmutating set { inner.projectionContext = newValue }
  }

  // MARK: Private

  private final class Inner {

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

}

// MARK: Identifiable

extension Projection: Identifiable where Value: Identifiable {
  public var id: Value.ID { value.id }
}
