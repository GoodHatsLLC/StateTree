// MARK: - InTransactionError

struct InTransactionError: Error { }

// MARK: - InternalStateInconsistency

public struct InternalStateInconsistency: Error, CustomStringConvertible {
  init(state: TreeStateRecord, scopes: [AnyScope]) {
    self.state = state
    let scopeIDs = Set(scopes.map(\.id))
    let nodeIDs = Set(state.nodeIDs)
    self.stateDiscrepancy = nodeIDs.subtracting(scopeIDs).sorted()
    self.scopeDiscrepancy = scopeIDs.subtracting(nodeIDs).sorted()
  }

  public let state: TreeStateRecord
  public let stateDiscrepancy: [NodeID]
  public let scopeDiscrepancy: [NodeID]
  public var description: String {
    """
    StateTree inconsistency found between recorded state and runtime scopes.
    This should never happen.

    - Node records without scopes: \(stateDiscrepancy)
    - Scopes without node records: \(scopeDiscrepancy)
    """
  }
}

// MARK: - CycleError

/// A `CycleError` indicates  a cyclical dependency between ``Node`` ``Rules`` in the tree.
///
/// When a cycle is detected this error is thrown and emitted to ``RuntimeConfiguration``
/// subscribers.
/// The cycle triggering change is reverted in order to keep the tree's state stable.
///
/// > Important:
///  A cycle is defined as any state update which triggers more than two updates to any node's
/// values.
public struct CycleError: Error, CustomStringConvertible {
  let cycle: [StateChangeMetadata]
  public var description: String {
    (
      ["🔄 Cycle Found:"]
        + cycle
        .map { "  - \($0)" }
    ).joined(separator: "\n")
  }
}

// MARK: - UnexpectedMemberTypeError

struct UnexpectedMemberTypeError: Error { }

// MARK: - NodeNotFoundError

struct NodeNotFoundError: Error { }

// MARK: - RootNodeMissingError

struct RootNodeMissingError: Error { }

// MARK: - InvalidInitialStateError

struct InvalidInitialStateError: Error { }

// MARK: - StartedTreeError

struct StartedTreeError: Error { }

// MARK: - InactiveTreeError

struct InactiveTreeError: Error { }