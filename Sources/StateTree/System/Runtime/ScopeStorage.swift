import Disposable

// MARK: - ScopeStorage

@TreeActor
final class ScopeStorage {

  // MARK: Lifecycle

  nonisolated init() { }

  // MARK: Internal

  var count: Int {
    scopeMap.count
  }

  var scopes: [AnyScope] {
    scopeMap.values.sorted(by: { $0.id < $1.id })
  }

  var scopeIDs: [NodeID] {
    scopeMap.keys.sorted()
  }

  var isEmpty: Bool {
    count == 0
  }

  func remove(_ scope: AnyScope) {
    remove(id: scope.id)
  }

  func remove(id: NodeID) {
    if let scope = scopeMap.removeValue(forKey: id) {
      valueDependencyTracker
        .removeValueDependencies(for: scope)
    }
  }

  func insert(_ scope: AnyScope) {
    assert(scopeMap[scope.id] == nil)
    scopeMap[scope.id] = scope
    valueDependencyTracker
      .addValueDependencies(for: scope)
  }

  func getScope(for id: NodeID) -> AnyScope? {
    scopeMap[id]
  }

  func getScopes(for ids: [NodeID]) -> [AnyScope] {
    let scopes = ids.compactMap { id in
      getScope(for: id)
    }
    assert(ids.count == scopes.count)
    return scopes
  }

  func contains(_ scopeID: NodeID) -> Bool {
    scopeMap[scopeID] != nil
  }

  func contains(_ scope: AnyScope) -> Bool {
    scopeMap[scope.id] != nil
  }

  func matching<N: Node>(node _: N) -> [AnyScope] {
    scopeMap
      .values
      .reduce(into: []) { acc, scope in
        if type(of: scope.underlying) == NodeScope<N>.self {
          acc.append(scope)
        }
      }
  }

  func dependentScopesForValue(id: FieldID) -> [AnyScope] {
    valueDependencyTracker
      .dependentScopesForValue(id: id)
      .compactMap { nodeID in
        scopeMap[nodeID]
      }
  }

  func depth(from scope: AnyScope?) -> Int {
    guard let scope
    else {
      return 0
    }

    return scope
      .childScopes
      .filter { $0.id != scope.id }
      .map { depth(from: $0) }
      .max()
      .map { $0 + 1 } ?? 0
  }

  // MARK: Private

  private var scopeMap: [NodeID: AnyScope] = [:]
  private var valueDependencyTracker: ValueDependencyTracker = .init()

}