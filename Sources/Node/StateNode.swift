import AccessTracker
import Dependencies
import Emitter
import Foundation
import ModelInterface
import Projection
import Utilities

// MARK: - StateNode

/// A public Node-creation API.
@MainActor
public protocol StateNode<State>: AnyObject, Identifiable {
  associatedtype State: ModelState
  nonisolated var id: AnyHashable { get }
  func createDownstream<IntermediateState, DownstreamState: ModelState>(
    id: AnyHashable,
    from projection: Projection<IntermediateState>,
    map: Bimapper<IntermediateState, DownstreamState>,
    initial: DownstreamState
  ) -> Node<DownstreamState>
}

/// The internal node API allowing Nodes to propagate change state
/// across the node tree.
@MainActor
protocol StateNodeInternal<State>: StateNode {
  func propagateDownstreamReportingValidity(changeID: UUID) -> Bool
  func remove(child: any StateNodeInternal)
  func propagateUpstreamIfRequired(changeID: UUID) -> Bool
  func cleanUpRegisteringForEvents(
    changeID: UUID,
    parentHasEmittedRootExternalChange: Bool
  )
}
