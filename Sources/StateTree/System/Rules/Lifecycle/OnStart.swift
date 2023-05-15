@_spi(Implementation) import Behavior
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnStart

/// Register an action to run as a Node is being stopped.
///
/// ```swift
/// OnStart {
///   // ...
/// }
/// ```
public struct OnStart<B: Behavior>: Rules where B.Input == Void,
  B.Output: Sendable
{

  // MARK: Lifecycle

  /// Register a synchronous action to run as a Node is started.
  ///
  /// - Parameter id: Optional:  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter action: The action run when the node is started.
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

  /// Register an asynchronous action to run as a Node is started.
  ///
  /// - Parameter id: Optional:  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter action: The action run when the node is started.
  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ action: @TreeActor @escaping () async -> Void
  ) where B == Behaviors.AsyncSingle<Void, Void, Never> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.AsyncSingle<Void, Void, Never> = Behaviors
      .make(id, input: Void.self) { await action() }
    self.callback = { scope, tracker in
      behavior.run(tracker: tracker, scope: scope, input: ())
    }
  }

  /// Register a stream action to run when a node is started
  ///
  /// - Parameter id: *Optional:*  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter maker: The action run to create the `AsyncSequence`.
  /// - Parameter onValue: A callback fired with values emitted by the `AsyncSequence`.
  /// - Parameter onFinish: A callback run if the `AsyncSequence` completes successfully.
  /// - Parameter onFailure: A callback run if the `AsyncSequence` fails with an error.
  public init<Seq: AsyncSequence>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    maker behaviorFunc: @escaping () async -> Seq,
    onValue: @escaping @TreeActor (_ value: Seq.Element) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) where B == Behaviors.Stream<Void, Seq.Element, Error> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.Stream<Void, Seq.Element, Error> = Behaviors
      .make(id, input: Void.self) {
        await behaviorFunc()
      }
    self.callback = { scope, tracker in
      behavior.run(
        tracker: tracker,
        scope: scope,
        input: (),
        handler: .init(onValue: onValue, onFinish: onFinish, onFailure: onFailure, onCancel: { })
      )
    }
  }

  /// Register a pre-existing ``Behavior`` to be run when a node is started.
  ///
  /// - Parameter id: *Optional*:  A *overriding* ``BehaviorID`` representing the ``Behavior``
  /// created to run the action.
  /// - Parameter runBehavior: The ``Behavior`` run as the node is started.
  /// - Parameter handler: *Optional*: A handler to run with values created by the ``Behavior``.
  public init(
    _ value: B.Input,
    _ id: BehaviorID? = nil,
    runBehavior behavior: B,
    handler: B.Handler? = nil
  ) {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    if let handler {
      self.callback = { scope, tracker in
        behavior.run(tracker: tracker, scope: scope, input: value, handler: handler)
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

  public mutating func applyRule(with context: RuleContext) throws {
    callback(scope, context.runtime.behaviorTracker)
  }

  public mutating func removeRule(with _: RuleContext) throws {
    scope.dispose()
  }

  public mutating func updateRule(
    from _: Self,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  private let callback: (any BehaviorScoping, BehaviorTracker) -> Void
  private let scope: BehaviorStage = .init()
}
