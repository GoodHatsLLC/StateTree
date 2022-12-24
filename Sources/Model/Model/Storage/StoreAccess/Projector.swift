import Projection

@MainActor
@dynamicMemberLookup
public struct Projector<M: Model> {

  nonisolated init(_ storage: _ModelStorage<M>) {
    self.storage = storage
  }

  public subscript<T: Equatable>(
    dynamicMember dynamicMember: WritableKeyPath<M.State, T>
  ) -> Projection<T> {
    project(keyPath: dynamicMember)
  }

  public func projection() -> Projection<M.State> {
    project(keyPath: \.self)
  }

  let storage: _ModelStorage<M>

  private func project<T: Equatable>(
    keyPath: WritableKeyPath<M.State, T>
  ) -> Projection<T> {
    .init(
      Access.CapturedAccess(
        getter: {
          storage.read(keyPath)
        },
        setter: { newValue in
          storage.write { state in
            state[keyPath: keyPath] = newValue
          }
        },
        isValid: { storage.activeModel.value != nil }
      )
    )
  }

}
