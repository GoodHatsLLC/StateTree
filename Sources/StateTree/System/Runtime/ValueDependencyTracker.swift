import TreeActor

struct ValueDependencyTracker {

  // MARK: Internal

  @TreeActor
  func dependentScopesForValue(id: FieldID) -> [NodeID] {
    valueDependencyToNodes[id].map(Array.init) ?? []
  }

  @TreeActor
  mutating func addValueDependencies(for scope: AnyScope) {
    let valueFieldDependencies = scope.valueFieldDependencies
    let nodeID = scope.nid
    nodeToValueDependency[nodeID] = valueFieldDependencies
    for valueDependency in valueFieldDependencies {
      valueDependencyToNodes[valueDependency, default: []]
        .insert(nodeID)
    }
  }

  @TreeActor
  mutating func removeValueDependencies(for scope: AnyScope) {
    let valueFieldDependencies = scope.valueFieldDependencies
    let nodeID = scope.nid
    nodeToValueDependency
      .removeValue(forKey: nodeID)
    for valueDependency in valueFieldDependencies {
      valueDependencyToNodes[valueDependency]?
        .remove(nodeID)
      if valueDependencyToNodes[valueDependency]?.isEmpty == true {
        valueDependencyToNodes
          .removeValue(forKey: valueDependency)
      }
    }
  }

  // MARK: Private

  private var nodeToValueDependency: [NodeID: Set<FieldID>] = [:]
  private var valueDependencyToNodes: [FieldID: Set<NodeID>] = [:]

}
