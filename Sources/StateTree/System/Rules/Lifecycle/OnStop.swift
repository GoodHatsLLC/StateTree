@_spi(Implementation) import Behavior
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnStop

/// Register a synchronous action to run as a Node is being stopped.
///
/// ```swift
/// OnStop {
///   // ...
///   // some cleanup
/// }
/// ```
public struct OnStop<B: Behavior>: Rules where B.Input == Void,
  B.Output: Sendable
{

  // MARK: Lifecycle

  /// Register a synchronous action to run as a Node is stopped.
  ///
  /// - Parameter id: *Optional:*  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter action: The action run when the node is stopped.
  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ action: @TreeActor @escaping () -> Void
  ) where B == Behaviors.SyncSingle<Void, Void, Never> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.SyncSingle<Void, Void, Never> = Behaviors
      .make(id, input: Void.self) { action() }
    self.callback = { scope, tracker in
      behavior.run(tracker: tracker, scope: scope, input: ())
    }
  }

  /// Register a pre-existing synchronous ``Behavior`` to be run when a node is stopped.
  ///
  /// - Parameter id: *Optional*:  A *overriding* ``BehaviorID`` representing the ``Behavior``
  /// created to run the action.
  /// - Parameter runBehavior: The ``Behavior`` run as the node is stopped.
  /// - Parameter handler: *Optional*: A handler to run with values created by the ``Behavior``.
  public init(
    _ id: BehaviorID? = nil,
    runBehavior behavior: B,
    handler: B.Handler? = nil
  )
    where B.Handler.SubscribeType == Synchronous
  {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    if let handler {
      self.callback = { scope, tracker in
        behavior.run(tracker: tracker, scope: scope, input: (), handler: handler)
      }
    } else {
      self.callback = { scope, tracker in
        behavior.run(tracker: tracker, scope: scope, input: ())
      }
    }
  }

  // MARK: Public

  public func act(
    for _: RuleLifecycle,
    with _: RuleContext
  )
    -> LifecycleResult
  {
    .init()
  }

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with context: RuleContext) throws {
    callback(scope, context.runtime.behaviorTracker)
    scope.dispose()
  }

  public mutating func updateRule(
    from _: Self,
    with _: RuleContext
  ) throws { }

  public mutating func syncToState(with _: RuleContext) throws { }

  // MARK: Private

  private let callback: (any BehaviorScoping, BehaviorTracker) -> Void
  private let scope: BehaviorStage = .init()
}
