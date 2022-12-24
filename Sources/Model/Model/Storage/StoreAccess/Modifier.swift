@MainActor
@dynamicMemberLookup
public struct Modifier<M: Model> {

  nonisolated init(_ storage: _ModelStorage<M>) {
    self.storage = storage
  }

  public subscript<T: Equatable>(
    dynamicMember dynamicMember: KeyPath<M.State, T>
  )
    -> T
  {
    storage.read(dynamicMember)
  }

  public subscript<T: Equatable>(
    dynamicMember dynamicMember: WritableKeyPath<M.State, T>
  )
    -> T
  {
    get { storage.read(dynamicMember) }
    nonmutating set {
      storage.write { $0[keyPath: dynamicMember] = newValue }
    }
  }

  let storage: _ModelStorage<M>

}
