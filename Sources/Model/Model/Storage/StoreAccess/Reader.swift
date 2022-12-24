@MainActor
@dynamicMemberLookup
public struct Reader<M: Model> {

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

  let storage: _ModelStorage<M>

}
