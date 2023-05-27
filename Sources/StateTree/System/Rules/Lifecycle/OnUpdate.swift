@_spi(Implementation) import Behavior
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnUpdate

/// `OnUpdate` registers an action to run when a value is created or changed.
///
/// > Tip: Unlike ``OnChange``, `OnUpdate` will fire for a node's initial value.
///
/// ```swift
/// OnUpdate(value) { value in
///   // ...
/// }
/// ```
public struct OnUpdate<B: Behavior>: Rules where B.Input: Equatable,
  B.Output: Sendable
{

  // MARK: Lifecycle

  /// Register a synchronous action to run when a value is created or changed.
  ///
  /// - Parameter value: the `Equatable` value whose changes trigger the `action`.
  /// - Parameter id: Optional:  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter action: The action run when the value is set or changed.
  public init<Input>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ value: Input,
    _ id: BehaviorID? = nil,
    action: @TreeActor @escaping (_ value: Input) -> Void
  ) where B == Behaviors.SyncSingle<Input, Void, Never> {
    self.value = value
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.SyncSingle<Input, Void, Never> = Behaviors
      .make(id, input: Input.self) { action($0) }
    self.callback = { scope, tracker, input in
      behavior.run(tracker: tracker, scope: scope, input: input)
    }
  }

  /// Register an asynchronous action to run when a value is created or changed.
  ///
  /// - Parameter value: the `Equatable` value whose changes trigger the `action`.
  /// - Parameter id: Optional:  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter action: The action run when the value is set or changed.
  public init<Input>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ value: Input,
    _ id: BehaviorID? = nil,
    action: @TreeActor @escaping (_ value: Input) async -> Void
  ) where B == Behaviors.AsyncSingle<Input, Void, Never> {
    self.value = value
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.AsyncSingle<Input, Void, Never> = Behaviors
      .make(id, input: B.Input.self) { await action($0) }
    self.callback = { scope, tracker, input in
      behavior.run(tracker: tracker, scope: scope, input: input)
    }
  }

  /// Register a stream action to run when a value is created or changed.
  /// The stream subscription is maintained only until the value changes again.
  ///
  /// - Parameter value: the `Equatable` value whose changes trigger the `action`.
  /// - Parameter id: Optional:  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter maker: The action run for the initial value and when changes to the value are
  /// detected. It must return an `AsyncSequence`.
  /// - Parameter onValue: A callback fired with values emitted by the `AsyncSequence`.
  /// - Parameter onFinish: A callback run if the `AsyncSequence` completes successfully.
  /// - Parameter onFailure: A callback run if the `AsyncSequence` fails with an error.
  public init<Input, Seq: AsyncSequence>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ value: Input,
    _ id: BehaviorID? = nil,
    run behaviorFunc: @escaping (_ value: Input) async -> Seq,
    onValue: @escaping @TreeActor (_ value: Seq.Element) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) where B == Behaviors.Stream<Input, Seq.Element, Error> {
    self.value = value
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.Stream<Input, Seq.Element, Error> = Behaviors
      .make(id, input: Input.self) {
        await behaviorFunc($0)
      }
    self.callback = { scope, tracker, value in
      behavior.run(
        tracker: tracker,
        scope: scope,
        input: value,
        handler: .init(onValue: onValue, onFinish: onFinish, onFailure: onFailure, onCancel: { })
      )
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
    callback(scope, context.runtime.behaviorTracker, value)
  }

  public mutating func removeRule(with _: RuleContext) throws {
    scope.dispose()
  }

  public mutating func updateRule(
    from other: Self,
    with context: RuleContext
  ) throws {
    if other.value != value {
      scope.reset()
      value = other.value
      callback(scope, context.runtime.behaviorTracker, value)
    }
  }

  public mutating func syncRuntime(with _: RuleContext) throws { }

  // MARK: Private

  private var value: B.Input
  private let callback: (any BehaviorScoping, BehaviorTracker, B.Input) -> Void
  private let scope: BehaviorStage = .init()
}

extension OnUpdate {

  /// Register a pre-existing ``Behavior`` to be run when a value is updated.
  ///
  /// - Parameter value: the `Equatable` value whose changes trigger the `action`.
  /// - Parameter id: *Optional*:  A *overriding* ``BehaviorID`` representing the ``Behavior``
  /// created to run the action.
  /// - Parameter runBehavior: The ``Behavior`` run when changes to the value are detected.
  /// - Parameter handler: *Optional*: A handler to run with values created by the ``Behavior``.
  public init(
    _ value: B.Input,
    _ id: BehaviorID? = nil,
    runBehavior behavior: B,
    handler: B.Handler? = nil
  )
    where B: Behavior
  {
    self.value = value
    var behavior = behavior
    if let id = id {
      behavior.setID(to: id)
    }
    if let handler {
      self.callback = { scope, tracker, value in
        behavior.run(tracker: tracker, scope: scope, input: value, handler: handler)
      }
    } else {
      self.callback = { scope, tracker, value in
        behavior.run(tracker: tracker, scope: scope, input: value)
      }
    }
  }
}
