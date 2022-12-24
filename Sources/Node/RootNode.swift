import Bimapping
import Dependencies
import Emitter
import Foundation
import ModelInterface
import Projection
import Utilities

// MARK: - RootNode

@MainActor
public final class RootNode: StateNodeInternal {

  nonisolated public init() {
    state = RootState()
  }

  public typealias State = RootState

  public struct RootState: ModelState {
    init() {}
  }

  public let id: AnyHashable = UUID.max

  public func createDownstream<IntermediateState, DownstreamState: ModelState>(
    id: AnyHashable,
    from projection: Projection<IntermediateState>,
    map: Bimapper<IntermediateState, DownstreamState>,
    initial: DownstreamState
  ) -> Node<DownstreamState> {
    let node = Node<DownstreamState>(
      id: id,
      upstream: self,
      source: projection,
      map: map,
      initial: initial
    )
    downstreamNodes.append(node)
    return node
  }

  var downstreamNodes: [any StateNodeInternal] = []

  func propagateDownstreamReportingValidity(changeID: UUID) -> Bool {
    true
  }

  func propagateUpstreamIfRequired(changeID: UUID) -> Bool {
    false
  }

  func cleanUpRegisteringForEvents(changeID: UUID, parentHasEmittedRootExternalChange: Bool) {}

  func remove(child: any StateNodeInternal) {
    downstreamNodes
      .removeAll(where: { $0 === child })
  }

  private var state: State

}
