// MARK: - TreeChanges

struct TreeChanges: TreeState {

  // MARK: Lifecycle

  init(
    addedScopes: [NodeID] = [],
    routedScopes: [NodeID] = [],
    removedScopes: [NodeID] = [],
    dirtyScopes: [NodeID] = [],
    updatedValues: [FieldID] = []
  ) {
    self.addedScopes = addedScopes
    self.routedScopes = routedScopes
    self.removedScopes = removedScopes
    self.dirtyScopes = dirtyScopes
    self.updatedValues = updatedValues
  }

  // MARK: Internal

  static let none = TreeChanges()

  let addedScopes: [NodeID]
  let routedScopes: [NodeID]
  let removedScopes: [NodeID]
  let dirtyScopes: [NodeID]
  let updatedValues: [FieldID]

  static func + (lhs: TreeChanges, rhs: TreeChanges) -> TreeChanges {
    .init(
      addedScopes: lhs.addedScopes + rhs.addedScopes,
      routedScopes: lhs.routedScopes + rhs.routedScopes,
      removedScopes: lhs.removedScopes + rhs.removedScopes,
      dirtyScopes: lhs.dirtyScopes + rhs.dirtyScopes,
      updatedValues: lhs.updatedValues + rhs.updatedValues
    )
  }

  mutating func take() -> TreeChanges {
    let current = self
    self = .none
    return current
  }

  mutating func put(_ changes: TreeChanges) {
    self = self + changes
  }

}
