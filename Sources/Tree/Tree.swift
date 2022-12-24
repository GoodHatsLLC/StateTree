import Dependencies
import Disposable
import Emitter
import Foundation
import Model
import Node
import SourceLocation
import Utilities

// MARK: - Tree

/// The `Tree` is responsible for running the StateTree graph.
@MainActor
public final class Tree<Root: Model> {

  /// Create a `Tree` object to run the StateTree graph
  ///
  /// The `Tree` is instantiated with the core state needed to
  /// create the domain model tree it is responsible for:
  /// * The value of the root ``Model`` ``ModelState``
  /// * A builder able to build the root ``Model`` given its ``Store``
  /// * Optionally: Any desired ``TreeHooks`` for ``Behavior`` interception in testing.
  ///
  /// The `Tree` must also be started with ``start(options:)`` before it
  /// will being managing models, their state, and their behaviors.
  public init(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    rootModelState: Root.State,
    hooks: TreeHooks = .init(),
    builder modelBuilder: (_ store: Store<Root>) -> Root
  ) {
    // CodeLocations are recorded during Model routing/instantiation
    // and used—in state recording and playback only—to identify the
    // routing action the model represents.
    // i.e. They're a stable identifier used to distinguish one model
    // from another even if the two models' state are the same.
    codeLocation = .init(
      fileID: fileID,
      line: line,
      column: column
    )

    // Stores are StateTree's state containers. They are the API that
    // models use to manage their state.
    // Each model is passed a store during instantiation — so they
    // must be constructed first.
    let store: Store<Root> = .init(
      rootState: rootModelState
    )

    // Models can have Annotations — property wrapper fields which define
    // behaviors associated with the model lifecycle — like `@DidActivate`.
    // These function similarly to SwiftUI's View property wrappers.
    //
    // A property wrapper in a struct can't get information about its container.
    // i.e. an inner struct—the property wrapper—can't directly interact with its model.
    //
    // In order for StateTree to associated a Model with its Annotations
    // we at some point need to collect the set of Annotations a Model has.
    //
    // To do this we:
    // * Use a global `ModelAnnotationCollector`
    // * Have our Annotation property wrappers register themselves with it
    //   as they are instantiated
    // * Collect the Annotations which are created *during a Model's init execution*
    // * Associated them with the model.
    //
    // This works because Swift guarantees fields are initialised before init returns.
    //
    // (Note: This approach avoids using reflection or runtime memory inspection — but
    // makes the assumption that models (and trees) are not concurrently initialised.)
    let eventReceiver = ModelAnnotationSink<Root>()

    rootModel = ModelAnnotationCollector
      .endpoint
      .using(receiver: eventReceiver) {
        // The builder passed to the Tree is used to
        // construct the Tree's root Model.
        modelBuilder(store)

        // At this point any Annotations on the root model have
        // are present in the eventReceiver.
      }
    annotations = eventReceiver.annotations

    // Record what the intended initial state for the model is.
    initState = rootModelState

    // Save TreeHooks.
    // TreeHooks are used to allow monitoring and overriding Behaviors
    // which allows for intercepting and replacing side effects / queries
    // from the StateTree and Models to the external world.
    // i.e. TreeHooks is allow for unit testing side effects like network
    // access.
    self.hooks = hooks
  }

  /// The ``Model`` entry-point and root of the domain state the tree manages.
  public let rootModel: Root
  /// The initial ``ModelState`` of the ``rootModel``
  public let initState: Root.State

  /// Subscribe to the `didStart` ``Emitter`` to receive a notification
  /// once the `Tree` has stated managing state.
  public var didStart: some Emitter<Void> {
    didStartSubject
  }

  private let annotations: [ModelAnnotation<Root>]
  private let codeLocation: SourceLocation
  private let hooks: TreeHooks
  private let didStartSubject = PublishSubject<Void>()

}

extension Tree {

  /// A `Tree` begin processing state changes and handling model routing once started.
  ///
  /// Optionally, non-default ``StartOption``s can be passed in `start()`:
  /// * ``LogLevel`` customisation. Assert (error), fatalError (critical), and unexpected warnings (warn)
  ///   level logs are printed by default. `Info` will print StateTree usage information like
  ///   time spent calculating model routes.
  /// * ``Dependency`` values applicable to all of the models in the StateTree should be passed here.
  /// * Time-Travel debugging (state recording and state playback) is configured with the `statePlayback` option.
  ///
  /// The tree returns an ``AnyDisposable`` which controls the `Tree's` lifecycle. When the `AnyDisposable`
  /// is released the tree will stop all work.
  /// (The ``AnyDisposable`` can be staged to prevent release, on a custom ``DisposalStage`` or  by using
  /// its convenience extension methods like ``stageIndefinitely()``)
  ///
  /// A stopped `Tree` can be restarted and new ``StartOption`` values can be passed.
  @MainActor
  public func start(
    options: [StartOption] = []
  ) throws
    -> AnyDisposable
  {
    // Create a stage to hold handles to long-running behaviors
    // within the Tree.
    let stage = DisposalStage()

    // Set up default values for the configuration StartOptions.
    var playbackMode: StatePlaybackMode? = nil
    var logThreshold: LogLevel = .warn
    var dependencyValues = DependencyValues.defaults

    // Replace the default configuration StartOptions with the
    // ones passed into the function.
    for option in options {
      switch option {
      case .logging(let threshold):
        logThreshold = threshold
      case .statePlayback(let mode):
        playbackMode = mode
      case .dependencies(let values):
        dependencyValues = values
      }
    }

    // Start the logger responsible for printing StateTree debug info
    // to the console and handling assertions.
    // (The logger is not exposed as a tool to consumers. It's only
    // intended for use with StateTree itself.)
    let logger = try startLogger(
      stage: stage,
      dependencyValues: dependencyValues,
      logThreshold: logThreshold
    )

    // Stores in our Model tree will need to behave differently
    // depending on whether we are in time-travel-debugging
    // playback mode, or running normally in interactive mode.
    // (Recording may or may not be enabled in interactive mode.)
    let startMode: StartMode
    if case .playback = playbackMode {
      startMode = .playback
    } else {
      startMode = .interactive
    }

    // StateTree automatically creates and tears down models
    // based on their parent's state — as per the rules defined in
    // the Model's `@RouteBuilder` `route(state:)` implementation.
    //
    // When a model is created it is 'routed to'.
    //
    // The different ways a model can be created are uniquely identified
    // by a SourcePath — a chain of source-code locations where the routing
    // logic executed.
    // These unique identifiers are used to map serialized State objects
    // to the correct Model when state is replayed in time-travel-debugging.
    //
    // Here we create the root Model's SourcePath from the CodeLocation
    // we recorded in `init`.
    let rootRouteIdentity =
      SourcePath
      .root(codeLocation)

    // Start the root model passing in the configuration collected so far.
    //
    // When starting a model will:
    // * synchronously route to its applicable child models based on its initial state.
    // * synchronously start its child models.
    // * begin to be able to host `Behaviors` — long running side effects which
    //   are torn down if the model stops before they complete.
    try rootModel
      ._startAsRoot(
        sourceIdentity: rootRouteIdentity,
        config: .init(
          hooks: hooks,
          startMode: startMode,
          dependencies: dependencyValues
        ),
        annotations: annotations
      )
      .stage(on: stage)

    // If we're configured for a time-travel-debugging mode, start
    // recording or enable playback.
    switch playbackMode {
    case nil:
      break
    case .record(let record):
      try startTreeRecorder(
        stateRecord: record,
        logger: logger
      )
      .stage(on: stage)
    case .playback(let player):
      try startTreeStatePlayer(
        player: player
      )
      .stage(on: stage)
    }

    // Emit a notification to any UI layer consumers we have to
    // indicate that the root Model, and so the Tree, has finished
    // its startup process and is available to be interacted with.
    didStartSubject.emit(.value(()))

    // We have started long-running processes and stored handles
    // to them on the DisposalStage.
    // We type-erase the stage to an AnyDisposable and pass it back
    // to our consumer to allow it to manage the full Tree's lifecycle.
    return stage.erase()
  }
}

// MARK: Logging
extension Tree {

  private func startLogger(
    stage: DisposalStage,
    dependencyValues: DependencyValues,
    logThreshold: LogLevel
  ) throws
    -> LogPrinter
  {
    try dependencyValues
      .logger
      .start(logThreshold: logThreshold)
      .stage(on: stage)

    try dependencyValues
      .logRate
      .start()
      .stage(on: stage)

    // FIXME: DependencyValues are intended for framework consumers, not implementation.
    // If we haven't already, start the default log printer.
    // This is a hack to allow us to print from an inactive store.
    if dependencyValues.logger !== DependencyValues.defaults.logger {
      try DependencyValues.defaults
        .logger
        .start(logThreshold: logThreshold)
        .stage(on: stage)
    }
    return dependencyValues.logger
  }
}

// MARK: TimeTravel debugging playback & recording
extension Tree {
  private func startTreeStatePlayer(
    player: some TreeStatePlayer
  ) throws
    -> AnyDisposable
  {
    player
      .selection
      .subscribe { [rootModel] index in
        do {
          try player.apply(
            index: index,
            rootModel: rootModel
          )
        } catch {
          player
            .selectionError
            .emit(.failed(error))
        }
      }
  }

  private func startTreeRecorder(
    stateRecord: any TreeStateRecord,
    logger: LogPrinter
  ) throws
    -> AnyDisposable
  {
    let recorder = rootModel.store._storage._recorder
    let disposable = hooks
      .didChangeEmitter
      .subscribe { identity in
        do {
          try self.record(
            with: recorder,
            into: stateRecord
          )
        } catch {
          logger.error(message: "\(error.localizedDescription) \(identity.debugDescription)")
        }
      }
    // record the initial state on start
    try record(
      with: recorder,
      into: stateRecord
    )
    return disposable
  }

  private func record(
    with recorder: _Recorder<Root.State>,
    into record: any TreeStateRecord
  ) throws {
    let accumulator = StateAccumulator { state, path in
      record.accumulateStatePatch(state: state, for: path)
    }
    try recorder.accumulateState(with: accumulator)
    record.flushStatePatches(
      time: Uptime.systemUptime
    )
  }

}

extension Tree {

  public var debugDescription: String {
    rootModel.debugDescription
  }
}
