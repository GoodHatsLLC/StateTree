import AccessTracker
import BehaviorInterface
import Bimapping
import Dependencies
import Disposable
import Emitter
import Foundation
import ModelInterface
import Node
import Projection
import SourceLocation
import Utilities

// MARK: - ActiveModel

/// The `ActiveModel` is a representation of a single Model's
/// State and functionality that is available to the Model
/// struct only when it has been Routed—and so is started
/// and hosted by another Model.
///
/// The `ActiveModel` handles interactions with the model's
/// `Node` State storage.
@usableFromInline
@MainActor
final class ActiveModel<M: Model> {

  nonisolated init(
    node: Node<State>,
    model: M,
    meta: StoreMeta
  ) {
    self.node = node
    self.model = model
    self.meta = meta
  }

  @usableFromInline
  typealias State = M.State

  let meta: StoreMeta

  let model: M

  /// The AccessTracker is used to avoid emitting update
  /// notifications for changes to fields that are not
  /// actually used on the UI layer.
  let accessTracker: AccessTracker<State> = .init()

  /// The `Node<State>` is the underlying store for
  /// this model's State —
  @usableFromInline
  let node: Node<State>

  private(set) var isStarted = false {
    didSet {
      updateLifecycleBindings()
    }
  }

  func isValid() -> Bool {
    node.isValid()
  }

  private var routePayload: M.Routes?
  private let activeStage = DisposalStage()
  private let activitySubject = ValueSubject(false)
}

// MARK: Identifiable, Equatable

extension ActiveModel: Identifiable, Equatable {
  nonisolated public var id: AnyHashable {
    node.id
  }

  @usableFromInline
  nonisolated static func == (lhs: ActiveModel, rhs: ActiveModel) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: update events

/// Notifications allowing the UI layer to know
/// when to update.
///
/// Different UI layers may observe different
/// event streams as needed.
extension ActiveModel {

  /// Emits the UUID associated with a tree update any time
  /// this model's routed submodels are changed.
  ///
  /// The UUID is constant each emitter notified for the change.
  @inlinable
  var routesDidChange: some Emitter<UUID> {
    node.routesDidChange
  }

  /// Emits the UUID associated with a tree update any time
  /// this model's state changes.
  ///
  /// The UUID is constant each emitter notified for the change.
  @inlinable
  var stateDidChange: some Emitter<UUID> {
    node.stateDidChange
  }

  /// Emits the UUID associated with a tree update when
  /// previously observed model state is updated.
  ///
  /// The UUID is constant each emitter notified for the change.
  @inlinable
  var observedStateDidChange: some Emitter<UUID> {
    node.observedStateDidChange
  }

  /// Emits the UUID associated with a tree update when
  /// this model is the topmost model that changed
  /// based on some write to the state tree.
  ///
  /// The UUID is constant each emitter notified for the change.
  @inlinable
  var subtreeDidChange: some Emitter<UUID> {
    node.subtreeDidChange
  }

  /// Emits the UUID associated with a tree update when the
  /// model is one of the a topmost models whose changing
  /// state is observed.
  ///
  /// i.e. If the topmost model in a change has state that is observed
  /// both `observedSubtreeDidChange` and ``subtreeDidChange``
  /// will emit.
  /// But if the topmost changed model is not directly observed its
  /// first descendants with observed changing state will emit to
  /// only to `observedSubtreeDidChange`.
  ///
  /// > Note: A change will not send `observedSubtreeDidChange` events
  /// to models that are new and not yet observed—and if the state triggering
  /// the routing that created the new models is not directly observed on the
  /// model it changed it will not trigger this emission there either.
  /// *As such:*
  /// Consumers relying on this emitter should also subscribe for notifications
  /// of routing changes via ``routesDidChange``.
  ///
  /// The UUID is constant each emitter notified for the change.
  @inlinable
  var observedSubtreeDidChange: some Emitter<UUID> {
    node.observedSubtreeDidChange
  }

}

// MARK: Store Accessors
extension ActiveModel {

  /// All of the @Route models that this
  /// model is currently hosting — erased.
  var submodels: [any Model] {
    routePayload?.models ?? []
  }

  /// Whether or not we are in time-travel
  /// debugging's playback mode.
  var isPlayback: Bool {
    meta.startMode == .playback
  }

  /// Indicates whether the model is currently accepting
  /// input from the UI layer.
  ///
  /// It will be interactive if:
  /// - time-travel debugging was not enabled in ``Tree.start(options:)``
  /// - time-travel debugging is current in recording mode.
  var isInteractive: Bool {
    meta.startMode == .interactive
  }

  /// Expose dependencies to the model layer.
  var dependencies: DependencyValues {
    meta.dependencies
  }

  /// Bind behavior cancellation handles to the model's lifecycle.
  /// Cancel immediately if called when a model is not active.
  func stage<D: Disposable>(
    _ disposable: D
  ) {
    if isInteractive {
      activeStage.stage(disposable)
    } else {
      disposable.dispose()
    }
  }

  /// Run a ``Behavior``, binding its cancellation to the model's lifecycle.
  func run<B: BehaviorType>(
    behavior: B,
    from codeLocation: SourceLocation
  )
    -> (() async throws -> B.Output)
  {
    let action = meta.hooks
      .wouldRun(behavior: behavior, from: codeLocation)

    switch action {
    case .cancel:
      return {
        throw BehaviorCancelled(
          id: behavior.id
        )
      }
    case .passthrough:
      return behavior.action
    case .swap(action: let act):
      let task = Task { try await act() }
      stage(
        task.erase()
      )
      meta.hooks
        .didRun(behavior: behavior, from: codeLocation)
      return { try await task.value }
    }
  }

  /// Start the ActiveModel, attaching to its underlying state storage Node.
  func start(annotations: [ModelAnnotation<M>]) throws -> AnyDisposable {

    // The Node needs to be able to trigger changes to the
    // model's routed submodels — but doesn't itself know
    // about the model's routing calls or the effects of the
    // state changes it tracks.
    //
    // (These are bad abstractions. See notes in Node.swift.)
    node.delegateHooks = .init(
      treeChangeDidFinish: { [meta] in
        meta.hooks.didWriteChange(at: meta.routeIdentity)
      },
      routeUpdater: { [weak self] in
        if let self {
          return try self.updateRoutesIfNeeded(startMode: self.meta.startMode)
        }
        return false
      },
      isNodeChangeExternal: { [accessTracker] change in
        accessTracker
          .accessesAffected(by: change)
      }
    )

    isStarted = true

    // trigger routing based on initial state
    _ = try updateRoutesIfNeeded(startMode: meta.startMode)

    // Indicate to consumers that the model has
    // fully started up.
    activitySubject.emit(.value(true))

    // Start any behaviors created by model annotation
    // property wrappers. e.g. @DidActivate, @DidUpdate
    startAnnotationBehaviors(annotations: annotations)

    // Return a disposable handle to our lifecycle
    // allowing our consumer to stop our behavior.
    return AnyDisposable { [weak self] in
      if let self {
        self.tearDown()
        self.activitySubject.emit(.value(false))
      }
    }
  }

  /// Start any `Behaviors` created by model annotation property wrappers.
  /// e.g. `@DidActivate` and `@DidUpdate`
  private func startAnnotationBehaviors(annotations: [ModelAnnotation<M>]) {
    let didActivateBehaviors =
      annotations
      .filter { $0.type == .didActivate }
      .map { $0.call }

    for behavior in didActivateBehaviors {
      behavior(self.model)
        .run(with: self.model)
    }

    let didUpdateBehaviors =
      annotations
      .filter { $0.type == .didUpdate }
      .map { $0.call }

    for behavior in didUpdateBehaviors {
      behavior(self.model)
        .run(with: self.model)
    }

    let disposable = node
      .stateDidChange
      .subscribeValue { [weak self] value in
        guard let self = self
        else { return }

        for behavior in didUpdateBehaviors {
          behavior(self.model)
            .run(with: self.model)
        }
      }
    stage(disposable)
  }

  /// Tear down our current state when
  /// notified by our consumer.
  private func tearDown() {
    isStarted = false
    _ = routePayload?.detach()
    routePayload = nil
    node.tearDown()
  }

  /// When starting and stopping we reset
  /// state and stop Behaviors that we have
  /// been hosting.
  private func updateLifecycleBindings() {
    if !isStarted {
      activeStage.reset()
    }
  }
}

// MARK: - Recording
extension ActiveModel {

  /// A method used by the recording functionality
  /// of time travel debugging to read the state
  /// of the Node tree.
  func accumulateState(with accumulator: StateAccumulator) throws {
    guard isInteractive
    else {
      return
    }
    accumulator.accumulate(
      state: node.read(),
      identity: meta.routeIdentity
    )
    for model in submodels {
      try model.accumulateState(with: accumulator)
    }
  }

}

extension ActiveModel {

  /// Allow the consumer to read from the underlying store.
  /// This method tracks which fields in the store have been
  /// read — allowing us to emit notifications for changes
  /// only to fields that actually matter to the consumer.
  func read<T: Equatable>(_ keyPath: KeyPath<State, T>) -> T {
    defer {
      accessTracker.registerAccess(keyPath)
    }
    return node.read()[keyPath: keyPath]
  }

  /// Allow the consumer to write to the underlying store.
  /// (If the store is not attached to the node tree writes
  /// are dropped.)
  func write(_ writer: (inout State) -> Void) {
    guard isInteractive
    else {
      return
    }
    var copy = node.read()
    writer(&copy)

    // The call to `updateIfNeeded(state:)` triggers
    // updates across the whole Node tree.
    _ = node.updateIfNeeded(state: copy)
  }

  /// Allow consumers to apply a full new state.
  /// (time-travel playback uses this.)
  func apply(state: State) {
    guard isPlayback
    else {
      return
    }
    _ = node.updateIfNeeded(state: state)
  }

  /// Update the source of the Node — i.e. it's parent
  /// in the StateTree.
  ///
  /// This is used during the routing payload evaluation
  /// and means that we can keep an instance of the Node
  /// around while changing what it is reading from.
  func update(source projection: some Accessor) throws {
    try node.update(source: projection)
  }
}

extension ActiveModel {

  func updateRoutesIfNeeded(startMode: StartMode?) throws -> Bool {
    meta.dependencies
      .logger
      .assertError(
        isValid(),
        message:
          """
          Attempted to updateRoutes on an invalid store.
          """,
        self
      )
    meta.dependencies
      .logger
      .assertError(
        isStarted,
        message:
          """
          Attempted to updateRoutes on an store that hadn't been started.
          """,
        self
      )

    let start = Uptime.systemUptime
    defer {
      let end = Uptime.systemUptime
      meta.dependencies.logRate.log(id: "updateRoutesIfNeeded", value: end - start)
    }

    let meta = meta.copyEdit { copy in
      copy.upstream = node
    }

    switch (routePayload, startMode) {
    case (.none, .none):
      // we're stopping but are already stopped
      return false
    case (.some(var currentRoutes), .none):
      // stopping
      let didChange = currentRoutes.detach()
      routePayload = nil
      meta.dependencies.logger
        .log("↪️", message: "Detached routes")
      return didChange
    case (.none, .some):
      // Start new routes

      // Make a constant version of the current State to be used by
      // the model to make routing decisions.
      let proxy = Access.ProxyAccess(Access.ConstantAccess(node.read()))
      let stateProjection: Projection<State> = Projection(proxy)

      // The local copy of the model is used to calculate new routes.
      var newRoutes = model.route(state: stateProjection)

      // Swap out the contant for a live access to the real Node state source.
      proxy.set(access: node.access)

      // Calculate whether or not the new route payload is an update
      // and indicate this to the caller.
      // (The route payload itself is new here but it may not actually
      // end up routing to any new models!)
      let didChange = try newRoutes.attach(parentMeta: meta)

      // Save the route payload so that we can compare against them next time
      // this function is called.
      routePayload = newRoutes

      meta.dependencies.logger
        .log("↪️", message: didChange ? "Changed routes" : "Unchanged routes")

      // Allow the caller to only change the model's submodel routes
      // if actually required.
      return didChange

    case (.some(let currentRoutes), .some):
      // update existing routes given new payload

      // Make a constant version of the current State to be used by
      // the model to make routing decisions.
      let proxy = Access.ProxyAccess(Access.ConstantAccess(node.read()))
      let stateProjection: Projection<State> = Projection(proxy)

      // The local copy of the model is used to calculate new routes.
      var newRoutes = model.route(state: stateProjection)

      // Swap out the contant for a live access to the real Node state source.
      proxy.set(access: node.access)

      // Calculate whether or not the new route payload is an update
      // to the routed submodels and indicate this to the caller.
      let didChange = try newRoutes.updateAttachment(
        from: currentRoutes,
        parentMeta: meta
      )

      // Save the route payload so that we can compare against them next time
      // this function is called.
      routePayload = newRoutes

      meta.dependencies.logger
        .log("↪️", message: didChange ? "Changed routes" : "Unchanged routes")

      return didChange
    }
  }
}
