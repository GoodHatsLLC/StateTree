import AccessTracker
import Bimapping
import Dependencies
import Emitter
import Foundation
import ModelInterface
import Projection
import SourceLocation
import Utilities

// MARK: - Node

/// The underlying state storage for a model.
/// The `Node` acts with its routing delegate (the
/// ``ActiveModel``) to:
/// 1. Receive changes to this Node's stored state.
/// 2. Push the state changes up towards the root
///    of the model tree until the change no longer
///    impacts state at that layer.
/// 3. Push the state change back down the model and
///    node tree, rerouting to create models as needed,
///    until the change no longer updates state at that
///    layer.
/// 4. Update external consumers of the state change.
@MainActor
public final class Node<State: ModelState>: StateNodeInternal {

  convenience init<H: Hashable>(
    source: some Accessor<State>,
    id: H,
    upstream: some StateNodeInternal
  ) {
    self.init(
      id: id,
      upstream: upstream,
      source: source,
      map: .passthrough(),
      initial: source.value
    )
  }

  init<H: Hashable, IntermediateState>(
    id: H,
    upstream: some StateNodeInternal,
    source: some Accessor<IntermediateState>,
    map: Bimapper<IntermediateState, State>,
    initial: State
  ) {
    self.id = id
    self.upstream = upstream
    let nodeAccess = Access.ValueAccess(initial)
    access = nodeAccess
    let initialSource = source.map(
      Transform.Stateful(
        map: map,
        upstream: source,
        downstream: nodeAccess,
        isValid: { _ in true }
      )
    )
    let proxy = Access.ProxyAccess(initialSource)
    upstreamSource = proxy
    let updateSource: (any Accessor) throws -> Void = { access in
      guard let source = access as? AnyAccess<IntermediateState>
      else {
        throw SourceUpdateTypeError()
      }
      proxy.set(
        access: source.map(
          Transform.Stateful(
            map: map,
            upstream: source,
            downstream: nodeAccess,
            isValid: { _ in true }
          )
        )
      )
    }
    attachUpstreamSourceFunc = updateSource
    lastKnownState = upstreamSource.value
  }

  // TODO: This API encapsulates some bad separations of concerns
  // - routeUpdater should either be modelled as a notification
  //   or perhaps receive new sub-nodes.
  // - isNodeChangeExternal requests information that is explicitly
  //   not present at the Node's layer of abstraction.
  //   If possible the Node should emit all important context and the
  //   layer that directly owns the AccessTracker should use it to
  //   filter the results.
  //
  /// `DelegateHooks` collects delegate functions implemented
  /// and provided by the `Node's` consumer (the ``ActiveModel``).
  public struct DelegateHooks {

    /// - Parameter treeChangeDidFinish:
    /// A callback invoked once per change. It is intended to represent a changed
    /// state across the entire tree — and not just at a node.
    /// - Parameter routeUpdater:
    /// A delegate callback provided by the consumer allowing an updated `Node` to
    /// synchronously trigger routing behavior which can update its child nodes.
    /// - Parameter isNodeChangeExternal:
    /// A delegating query to the model layer allowing the `Node` to find information
    /// about the external visibility of the state change—in turn allowing it to make
    /// decisions about the appropriate semantics for the update emission.
    public init(
      treeChangeDidFinish: @escaping () -> Void,
      routeUpdater: @escaping (@MainActor () throws -> Bool),
      isNodeChangeExternal: @escaping (@MainActor (_ change: Change<State>) -> Bool)
    ) {
      self.treeChangeDidFinish = treeChangeDidFinish
      self.routeUpdater = routeUpdater
      self.isNodeChangeExternal = isNodeChangeExternal
    }

    fileprivate let treeChangeDidFinish: () -> Void
    fileprivate let routeUpdater: @MainActor () throws -> Bool
    fileprivate let isNodeChangeExternal: @MainActor (_ node: Change<State>) -> Bool
  }

  nonisolated public let id: AnyHashable

  // Notifications of state changes are emitted to various
  // streams based on what effect they have on the tree.
  public let routesDidChange: PublishSubject<UUID> = .init()
  public let stateDidChange: PublishSubject<UUID> = .init()
  public let observedStateDidChange: PublishSubject<UUID> = .init()
  public let subtreeDidChange: PublishSubject<UUID> = .init()
  public let observedSubtreeDidChange: PublishSubject<UUID> = .init()

  // Local state required for the node tree update pass.
  public var lastKnownState: State
  public var delegateHooks: DelegateHooks?

  // References to parent and child nodes used in
  // the state update pass.
  let upstream: any StateNodeInternal
  var downstreamNodes: [any StateNodeInternal] = []

  // The source of the local state — provided by the
  // upstream node — and potentially updated based on
  // upstream changes.
  let upstreamSource: Access.ProxyAccess<State>

  // The access to local state that is passed to downstream
  // nodes. This is the canonical source for model state.
  public let access: Access.ValueAccess<State>

  // Local storage for information about a change that
  // in in progress — i.e. currently being pushed
  // across the Node tree.
  private var changeInProgress: ChangeInProgressDetails<State>?

  // A closure that can update the update the local
  // upstream source to an incoming value — and is
  // internally aware what the type of that value
  // should be.
  private let attachUpstreamSourceFunc: (any Accessor) throws -> Void
}

// MARK: - Node state access API
extension Node {

  /// Allow consumers to read state.
  public func read() -> State {
    access.value
  }

  /// Given a proposed new state, update if it is a change.
  /// Notify the consumer of whether the new state entailed a change.
  public func updateIfNeeded(state newState: State) -> Bool {
    guard lastKnownState != newState
    else {
      // An update is not needed.
      return false
    }

    // Change our node's state.
    // Our source is a projection and changing it will update
    // its source — the upstream projection.
    upstreamSource.value = newState
    access.value = newState

    // track the update
    let changeID = UUID()

    // begin change propagation, notifying upstream of changes.
    let currentNodeDidChange = propagateUpstreamIfRequired(
      changeID: changeID
    )

    DependencyValues.defaults.logger.assertError(
      currentNodeDidChange,
      message: "The initial changed node should have actually changed."
    )

    // We performed an update
    return true
  }

  /// Propagate the State at the Node up the node tree.
  ///
  /// The State will propagate upwards, returning true, only
  /// as long as it entails a state change in the upstream node.
  /// Once the upstream node does not update based on a cange
  /// the call returns false.
  func propagateUpstreamIfRequired(changeID: UUID) -> Bool {
    guard let delegateHooks
    else {
      DependencyValues.defaults.logger.error(
        message: "delegateHooks should be set on \(self)"
      )
      return false
    }

    let update = access.value

    // If this node is unchanged, indicated so to the node below it.
    if lastKnownState == update {
      return false
    }

    changeInProgress = ChangeInProgressDetails(
      id: changeID,
      originalState: lastKnownState,
      newState: update
    )

    // Set the value inferred from downstream as our source,
    // propagating it upstream.
    upstreamSource.value = update

    // Recurse this method to the upstream node which should now
    // have received its mapping of our state change.
    // Record if it reports that our immediate upstream changed.
    let upstreamDidUpdate =
      upstream
      .propagateUpstreamIfRequired(
        changeID: changeID
      )

    if !upstreamDidUpdate {
      // The topmost changed node triggers downwards propagation to
      // update the rest of the tree based on the highest level changes.
      //
      // From here we will re-resolve downstream state, clean up
      // our change tracking information, and message external consumers
      // to notify them of updates.
      coordinateDownstreamFinalization(
        changeID: changeID,
        delegateHooks: delegateHooks
      )
    }
    return true
  }

  /// A helper method called on the topmost node affected by a change.
  ///
  /// It manages:
  /// * Resolving downstream state across the tree via
  ///   ``propagateDownstreamReportingValidity(changeID:)``
  /// * Cleaning up stored intermediate state (``changeInProgress`` and
  /// ``lastKnownState``)
  /// * Coordinating messaging update event emitters to notify external
  ///   consumers including the UI layer of updates.
  private func coordinateDownstreamFinalization(
    changeID: UUID,
    delegateHooks: DelegateHooks
  ) {
    DependencyValues.defaults.logger.log(
      "♻️", message: "subtreeDidChange root: \(self)", changeID
    )

    // Propagate changes downstream.
    let isValid = propagateDownstreamReportingValidity(
      changeID: changeID
    )
    DependencyValues.defaults.logger.assertError(
      isValid,
      message: "The topmost changed node can't be invalidated in a change",
      self
    )

    // We clean up temporary state, and emit change notifications.
    cleanUpRegisteringForEvents(
      changeID: changeID,
      parentHasEmittedRootExternalChange: false
    )

    // Once all other changes have been emitted, the root node
    // in the change can emit to indicate all change behavior
    // is done.

    // Emit the final per-node change notification to *this* root-change node.
    subtreeDidChange.emit(.value(changeID))

    // Some consumer logic doesn't listen to specific nodes but rather to
    // the Tree for changes. (i.e. TimeTravel recording/replay)
    // Notify our delegate that our change work finished.
    delegateHooks.treeChangeDidFinish()
  }

  /// Propagate changes downstream, returning a bool indicating whether this node is still valid.
  func propagateDownstreamReportingValidity(changeID: UUID) -> Bool {
    guard let delegateHooks
    else {
      DependencyValues.defaults.logger.error(
        message: "delegateHooks should be set on \(self)"
      )
      return false
    }

    // Report if the change upstream invalidated this node
    guard upstreamSource.isValid()
    else {
      return false
    }

    // Calculate the finalized value for this node from its upstream
    let updatedState = upstreamSource.value

    var changeInProgress: ChangeInProgressDetails<State>
    if var record = self.changeInProgress {
      // Update the new value in the record.
      record.newState = updatedState
      changeInProgress = record
    } else {
      // If this is a new node or one below the initial change it
      // won't yet have a changeInProgress. Make one from scratch.
      changeInProgress = ChangeInProgressDetails(
        id: changeID,
        originalState: lastKnownState,
        newState: updatedState
      )
    }

    // If the node's final value didn't change AND it wasn't touched during
    // the propagateUpstream pass, it can't have changes below it and we can stop.
    //
    // Return indicating validity — but ending further propagation.
    let updateChange = changeInProgress.getChange()
    let isInChangeCascade = updateChange != nil || self.changeInProgress != nil
    guard isInChangeCascade
    else {
      DependencyValues.defaults.logger.log(
        "♻️", message: "change propagation terminus: \(self)", changeID
      )
      return true
    }

    if let updateChange {
      // We are tracking the previous and new state locally now.
      // We stop tracking the previous state on the Node instance.
      lastKnownState = updatedState

      // Call a delegating function to see if the change affected
      // external consumers.
      changeInProgress.isExternal = delegateHooks.isNodeChangeExternal(updateChange)

      // Call a delegating function allow the node's owner to update
      // its children based on the new state.
      // (i.e. allow the model layer to do routing at this point.)
      do {
        changeInProgress.didUpdateRoutes = try delegateHooks.routeUpdater()
      } catch {
        DependencyValues.defaults.logger.error(
          message: "routing failed given state change at \(self)",
          error,
          updateChange
        )
        // If the routeUpdater fails, this node is not able
        // to do its job fully and reports itself invalid.
        return false
      }
    }

    // Propagate the change downstream.
    // Any nodes returning false are invalid.
    let validNodes =
      downstreamNodes
      .filter { node in
        node.propagateDownstreamReportingValidity(changeID: changeID)
      }

    if validNodes.count != downstreamNodes.count {
      DependencyValues.defaults.logger.assertError(
        validNodes.count == downstreamNodes.count,
        message:
          """
          Invalid nodes were found downstream from \(self) after re-routing.
          Routing should remove invalid nodes.
          """,
        validNodes,
        downstreamNodes
      )
      // Remove invalidated downstream nodes.
      downstreamNodes = validNodes
    }

    // Store the changeInProgress information on this instance.
    self.changeInProgress = changeInProgress

    // The node has finished its update tasks and can signal
    // to its parent that it is valid.
    return true
  }

  func cleanUpRegisteringForEvents(
    changeID: UUID,
    parentHasEmittedRootExternalChange: Bool
  ) {
    // We emit to many different streams with different semantics.
    //
    // Different platforms and contexts have different requirements for updates.
    // * UIKit likely needs to know about about each changing node since
    //   we have no reason to think node interdependencies are modelled there.
    // * StateTree time travel debugging (recording/playback) records the whole
    //   tree for each change — and so doesn't listen to any particular node.
    // * SwiftUI only needs to know about the root-most change that is
    //   observed — it will update the view tree from the root-most change.
    //   ... but it's also possible that the root-most changed Node isn't
    //   actually observed or important to the SwiftUI-based consumer.
    //   In that case it's preferable to notify it of the root-most *nodes* in
    //   a change which *are* observed.
    // * Etc.
    // * We emit changes notifications that capture the semantics of how the
    //   change affected the models. The UI integration layer libraries like
    //   StateTreeSwiftUI can listen to whatever is useful to them.
    // * (And the cost of emitting to an unsubscribed Emitter is low).

    // If this node is not marked as touched, nodes below it will not be either.
    guard let changeInProgress
    else {
      // Exit the change pass.
      return
    }

    DependencyValues.defaults.logger.assertError(
      changeInProgress.id == changeID,
      message: "temporary state from a change was left on the node"
    )

    // Remove our the temporary instance state.
    // We have now fully cleaned up.
    self.changeInProgress = nil

    // When the node's state change leads to its model
    // changing the submodels it directly owns.
    if changeInProgress.didUpdateRoutes {
      routesDidChange.emit(.value(changeID))
    }

    // Updates emitted for any change.
    if changeInProgress.getChange() != nil {
      stateDidChange.emit(.value(changeID))
    }

    // Emitted when the delegateHooks report that external
    // consumers actually observe the change.
    if changeInProgress.isExternal {
      observedStateDidChange.emit(.value(changeID))
    }

    // Emitted when the Node has no parents which have observed
    // changes — and its own changes are reported as externally observed.
    var parentHasEmittedRootExternalChange = parentHasEmittedRootExternalChange
    if changeInProgress.isExternal, !parentHasEmittedRootExternalChange {
      parentHasEmittedRootExternalChange = true
      observedSubtreeDidChange.emit(.value(changeID))
    }

    // Continue finalising changed nodes independent of whether this one changed.
    for node in downstreamNodes {
      node.cleanUpRegisteringForEvents(
        changeID: changeID,
        parentHasEmittedRootExternalChange: parentHasEmittedRootExternalChange
      )
    }
  }

}

// MARK: Node lifecycle API.
extension Node {
  /// The node is only valid while its connection to its
  /// parent node is valid.
  public func isValid() -> Bool {
    upstreamSource.isValid()
  }

  /// Allow the consumer to update the Node's source data.
  ///
  /// > Warning: The source passed here **must** provide the same
  /// type as the Node was created with (i.e. `IntermediateState`
  /// in its parent's ``createDownstream(id:from:map:initial)``
  /// that was used to create it.)
  public func update(source: some Accessor) throws {
    try attachUpstreamSourceFunc(source.erase())
  }

  /// Create a Node that is downstream from this one.
  ///
  /// The created Node's state type, `DownstreamState` may or may not
  /// be the same as the `IntermediateState`.
  ///
  /// `IntermediateState` is the type of `State` that is passed
  /// into the node as its incoming `Projection`. This projection
  /// must be stateless as it is recreated repeatedly — whenever the upstream
  /// Model's ``route(state:)`` call.
  ///
  /// - The Node's source is its connection to its upstream's State.
  /// - This connection is defined the routing Model's ``route(state:)``
  /// - ``route(state:)`` is called when a Model's direct Node's
  ///   state changes — to let StateTree recalculate appropriate submodels.
  /// - i.e. A Node's source is re-created every time ``route(state:)``
  ///   is called on the upstream Model that created it..
  ///
  /// This means that the incoming state projection **must** not be stateful.
  /// However, Projections *can* maintain state, and projections which do are
  /// more 'powerful' — able to model more complex behavior.
  ///
  /// The `IntermediateState` vs `DownstreamState` distinction attempts
  /// to square this circle.
  /// Mapping state *after* the incoming `Projection<IntermediateState>`
  /// is however maintained across ``Model.route(state:)`` as it is stored here —
  /// `upstreamSource` in the `Node` itself.
  ///
  /// > Context:
  /// > A Projection (or Binding) that captures external values in its get or set
  /// > closures is stateful.
  /// > `StateTree` and `Projection` attempt to discourage this by
  /// >  explicitly naming operators that allow this. e.g.`statefulMap`.
  /// >
  /// > Unfortunately, `StateTree` also relies heavily on the integration
  /// > of the ``Bimapping`` interface into ``Projection``.
  /// >
  /// > A regular ``Bimapping.Bimapper`` created outside of a `Projection`
  /// > is stateless — but it can only act on two instances that already exist.
  /// > i.e. ``Bimapping.update(a:from)``.
  /// >
  /// > `Projections` however need to be able to *create* a downstream
  /// > value from an upstream. Hence ``Projection.statefulMap(into:isValid:mapping:)``,
  /// > like ``createDownstream(id:from:map:initial)`` which abstracts over
  /// > it (i.e. *this* method), need to take an initial downstream state parameter.
  /// >
  /// > This is one of the least satisfying aspects of the entire `StateTree`
  /// > project.
  /// >
  /// > Here, it means we need to take this `IntermediateState`,
  /// > and pass it through to the initialiser which implicitly stores it in the
  /// > `attachUpstreamSourceFunc` property.
  /// > The closure is then executed on a type-erased `IntermediateState`
  /// > input to recreate the upstream `Projection` that is proxied via
  /// > `upstreamSource`.
  /// >
  /// > This feels rather too complex and rather too fragile.
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

  /// End the Node lifecycle removing resources
  public func tearDown() {
    upstream.remove(child: self)
    delegateHooks = nil
  }

  /// Remove the node if it is a child node.
  func remove(child: any StateNodeInternal) {
    downstreamNodes
      .removeAll(where: { $0 === child })
  }

}
