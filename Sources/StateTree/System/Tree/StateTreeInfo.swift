import Behaviors
import TreeActor
// MARK: - StateTreeInfo

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

  /// The ``Tree`` that was starting to make the ``TreeLifetime``.
  @TreeActor  public var tree: Tree {
    runtime.tree
  }

  /// The ``NodeID`` of the tree's root ``Node`` if the tree is active.
  @TreeActor  public var rootID: NodeID? {
    runtime.root?.nid
  }

  /// The ``NodeID`` of each active nodes on the ``Tree``.
  @TreeActor  public var nodeIDs: [NodeID] {
    runtime.nodeIDs
  }

  /// Whether the ``Tree`` is active.
  /// This will be `true` from when a ``TreeLifetime`` is created with
  /// ``Tree/start(root:from:dependencies:configuration:)`` to when
  /// ``TreeLifetime/dispose()`` is called.
  @TreeActor  public var isActive: Bool {
    runtime.isActive
  }

  /// The number of ``Node``s active in the ``Tree``.
  @TreeActor  public var nodeCount: Int {
    runtime.nodeIDs.count
  }

  /// The height of the ``Node`` tree managed by the ``Tree``.
  ///
  /// The tree 'height' is count of nodes in the longest path from the tree's root node to a left
  /// node.
  /// An inactive tree has no root node and so has a height of zero.
  @TreeActor  public var height: Int {
    scopes.depth(
      from: runtime.root
    ) + ((runtime.root?.isActive ?? false) ? 1 : 0)
  }

  /// Behaviors invoked since the ``TreeLifetime``'s creation.
  ///
  /// Behaviors are tracked immediately and synchronously on creation
  /// but their subscriptions may be to concurrently accessed resources.
  /// Behaviors present here may not yet be started (``TreeLifetime/awaitReady()``)
  /// or resolved (``TreeLifetime/behaviorResolutions``).
  @TreeActor  public var behaviors: [Behaviors.Resolution] {
    runtime.behaviorManager.behaviors
  }

  /// The pending ``Intent`` if one exists.
  ///
  /// The most recent ``Intent`` signalled with ``TreeLifetime/signal(intent:)``
  /// remains pending until it finishes or is replaced.
  @TreeActor  public var pendingIntent: Intent? {
    runtime.activeIntent?.intent
  }

  /// The StateTree runtime's consistency with its tracked state.
  ///
  /// The runtime is inconsistent with the state record *while* a state change transaction is in
  /// progress. However transactions synchronously execute on the `TreeActor` to which
  /// all API calls—including this one—are also isolated.
  ///
  /// External consumers should never be able to receive a `false` value from this field.
  @TreeActor  public var isConsistent: Bool {
    let isConsistent = runtime.isConsistent
    assert(isConsistent)
    return isConsistent
  }

  // MARK: Internal

  let runtime: Runtime
  let scopes: ScopeStorage

}
