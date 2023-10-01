import TreeActor

// MARK: - TreeValueAccess

@TreeActor
protocol TreeValueAccess {
  var treeValue: TreeValue? { get nonmutating set }
}

// MARK: - TreeValue

@TreeActor
struct TreeValue {
  let runtime: Runtime
  let id: FieldID
  var scope: AnyScope? {
    try? runtime.getScope(for: id.nodeID)
  }

  func getValue<T: TreeState>(as t: T.Type) -> T? {
    runtime.getValue(field: id, as: t)
  }

  func setValue(to newValue: some TreeState) {
    runtime.setValue(field: id, to: newValue)
  }
}

// MARK: - ValueField

protocol ValueField<WrappedValue> {
  associatedtype WrappedValue: TreeState
  var access: any TreeValueAccess { get }
  var anyInitial: any TreeState { get }
  var initial: WrappedValue { get }
}

// MARK: - Value

/// A property wrapper whose wrappedValue is managed by StateTree
@propertyWrapper
public struct Value<WrappedValue: TreeState>: ValueField, Accessor {

  // MARK: Lifecycle

  public init(wrappedValue: WrappedValue) {
    self.initial = wrappedValue
    self.inner = .init(initialValue: wrappedValue)
  }

  // MARK: Public

  public typealias WrappedValue = WrappedValue

  @_spi(Implementation) public let initial: WrappedValue

  /// The projectedValue of a ``Value`` is a `Projection`.
  ///
  /// Projections allow references to managed state from 'higher' ``Node``s closer to the tree root
  /// to be shared with
  /// 'lower' nodes closer to its leaves.
  public var projectedValue: Projection<WrappedValue> {
    .init(
      self,
      initial: initial
    )
  }

  /// The state value managed by StateTree.
  ///
  /// Updates to this value cause any ``Node`` which uses it, either through direct ownership or
  /// through ``projectedValue`` access,
  /// to be reevaluated. This will potentially cause the tree itself to reflow.
  @TreeActor public var wrappedValue: WrappedValue {
    get {
      let value = inner
        .treeValue?
        .getValue(as: WrappedValue.self) ?? inner.cache
      return value
    }
    nonmutating set {
      inner.cache = newValue
      inner
        .treeValue?
        .setValue(to: newValue)
    }
  }

  @_spi(Implementation) public var value: WrappedValue {
    get {
      wrappedValue
    }
    nonmutating set {
      wrappedValue = newValue
    }
  }

  @_spi(Implementation) public var source: ProjectionSource {
    if let id = inner.treeValue?.id {
      return .valueField(id)
    } else {
      return .programmatic
    }
  }

  @_spi(Implementation)
  public func isValid() -> Bool {
    inner.treeValue != nil
  }

  // MARK: Internal

  @TreeActor
  final class InnerValue: TreeValueAccess {

    // MARK: Lifecycle

    init(initialValue: WrappedValue) {
      self.cache = initialValue
    }

    // MARK: Internal

    var treeValue: TreeValue?
    var cache: WrappedValue
  }

  let inner: InnerValue

  var access: any TreeValueAccess { inner }
  var anyInitial: any TreeState {
    initial
  }

}
