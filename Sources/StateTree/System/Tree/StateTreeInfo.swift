// MARK: - StateTreeInfo

@TreeActor
public struct StateTreeInfo {

  // MARK: Lifecycle

  init(
    runtime: Runtime,
    scopes: ScopeStorage
  ) {
    self.runtime = runtime
    self.scopes = scopes
  }

  // MARK: Public

  public var rootID: NodeID? {
    runtime.root?.nid
  }

  public var nodeIDs: [NodeID] {
    runtime.nodeIDs
  }

  public var isActive: Bool {
    runtime.isActive
  }

  public var nodeCount: Int {
    runtime.nodeIDs.count
  }

  public var height: Int {
    scopes.depth(
      from: runtime.root
    ) + ((runtime.root?.isActive ?? false) ? 1 : 0)
  }

  public var pendingIntent: Intent? {
    runtime.activeIntent?.intent
  }

  public var isEmpty: Bool {
    runtime.runtimeEmpty
      && runtime.stateEmpty
  }

  public var isConsistent: Bool {
    let isConsistent = runtime.isConsistent
    assert(isConsistent)
    return isConsistent
  }

  // MARK: Internal

  let runtime: Runtime
  let scopes: ScopeStorage

}
