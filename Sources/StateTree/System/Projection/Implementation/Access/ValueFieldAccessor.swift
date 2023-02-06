import TreeState

/// An ``Accessor`` which refers to `@Value` field in a tree
public struct ValueFieldAccessor<Value: TreeState>: Accessor {

  // MARK: Lifecycle

  nonisolated init(
    access: TreeValueAccess,
    initial: Value
  ) {
    self.isValidFunc = { access.treeValue != nil }
    self.getFunc = {
      access.treeValue?.getValue(as: Value.self) ?? initial
    }
    self.setFunc = { newValue in
      access.treeValue?.setValue(to: newValue)
    }
    self.sourceFunc = {
      (access.treeValue?.id).map { .valueField($0) } ?? .invalid
    }
  }

  // MARK: Public

  @TreeActor public var value: Value {
    get {
      getFunc()
    }
    nonmutating set {
      setFunc(newValue)
    }
  }

  // MARK: Internal

  @TreeActor var source: ProjectionSource {
    sourceFunc()
  }

  @TreeActor
  func isValid() -> Bool {
    isValidFunc()
  }

  // MARK: Private

  private let sourceFunc: @TreeActor () -> ProjectionSource
  private let isValidFunc: @TreeActor () -> Bool
  private let getFunc: @TreeActor () -> Value
  private let setFunc: @TreeActor (Value) -> Void

}
