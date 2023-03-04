import TreeState

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

protocol ValueField<Wrapped> {
  associatedtype Wrapped: TreeState
  var access: TreeValueAccess { get }
  var anyInitial: any TreeState { get }
  var initial: Wrapped { get }
}

// MARK: - TreeValueAccess

@TreeActor
final class TreeValueAccess {

  // MARK: Lifecycle

  nonisolated init() { }

  // MARK: Internal

  var treeValue: TreeValue?
}

// MARK: - Value

@propertyWrapper
public struct Value<Wrapped: TreeState>: ValueField {

  // MARK: Lifecycle

  public init(wrappedValue: Wrapped) {
    self.initial = wrappedValue
    self.cache = .init(value: wrappedValue)
  }

  // MARK: Public

  public typealias WrappedValue = Wrapped

  @TreeActor public var wrappedValue: Wrapped {
    get {
      let value = access
        .treeValue?
        .getValue(as: Wrapped.self) ?? cache.value
      cache.value = value
      return value
    }
    nonmutating set {
      cache.value = newValue
      access
        .treeValue?
        .setValue(to: newValue)
    }
  }

  public var projectedValue: Projection<Wrapped> {
    .init(
      ValueFieldAccessor(
        access: access,
        initial: initial
      ),
      initial: initial
    )
  }

  // MARK: Internal

  let access: TreeValueAccess = .init()

  let initial: Wrapped

  var anyInitial: any TreeState {
    initial
  }

  // MARK: Private

  private let cache: Ref<Wrapped>

}
