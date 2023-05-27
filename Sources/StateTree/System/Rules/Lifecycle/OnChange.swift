@_spi(Implementation) import Behavior
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnChange

/// `OnChange` registers an action to run when a value is changed. The action
/// is passed both the `old` and `new` values.
///
/// The action is run as a `Behavior` and can be swapped
/// out in testing by assigning it a `BehaviorID`.
///
/// ```swift
/// OnChange(value) { old, new in
///   // ...
/// }
/// ```
///
/// > Tip: Unlike ``OnUpdate`` which fires during Node start when there is no
/// previous value, `OnChange` will not fire unless the previous value is known.
public struct OnChange<Value: Equatable, B: Behavior>: Rules where B.Input == (Value, Value),
  B.Output: Sendable
{

  // MARK: Lifecycle

  /// Register a synchronous action to run when a value is changed.
  ///
  /// - Parameter value: the `Equatable` value whose changes trigger the `action`.
  /// - Parameter id: Optional:  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter action: The action run when changes to the value are detected.
  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ value: Value,
    _ id: BehaviorID? = nil,
    action: @TreeActor @escaping (_ oldValue: Value, _ newValue: Value) -> Void
  ) where B == Behaviors.SyncSingle<(Value, Value), Void, Never> {
    self.value = value
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.SyncSingle<(Value, Value), Void, Never> = Behaviors
      .make(id, input: (Value, Value).self) { action($0.0, $0.1) }
    self.callback = { scope, tracker, input in
      behavior.run(tracker: tracker, scope: scope, input: input)
    }
  }

  /// Register an asynchronous action to run when a value is changed.
  ///
  /// - Parameter value: the `Equatable` value whose changes trigger the `action`.
  /// - Parameter id: Optional:  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter action: The action run when changes to the value are detected.
  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ value: Value,
    _ id: BehaviorID? = nil,
    action: @TreeActor @escaping (_ oldValue: Value, _ newValue: Value) async -> Void
  ) where B == Behaviors.AsyncSingle<(Value, Value), Void, Never> {
    self.value = value
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.AsyncSingle<(Value, Value), Void, Never> = Behaviors
      .make(id, input: (Value, Value).self) { await action($0.0, $0.1) }
    self.callback = { scope, tracker, input in
      behavior.run(tracker: tracker, scope: scope, input: input)
    }
  }

  /// Register a stream action to run when a value is changed.
  /// The stream subscription is maintained only until the value changes again.
  ///
  /// - Parameter value: the `Equatable` value whose changes trigger the `action`.
  /// - Parameter id: Optional:  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter maker: The action run when changes to the value are detected. It must return an
  /// `AsyncSequence`.
  /// - Parameter onValue: A callback fired with values emitted by the `AsyncSequence`.
  /// - Parameter onFinish: A callback run if the `AsyncSequence` completes successfully.
  /// - Parameter onFailure: A callback run if the `AsyncSequence` fails with an error.
  public init<Seq: AsyncSequence>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ value: Value,
    _ id: BehaviorID? = nil,
    maker behaviorFunc: @escaping (_ oldValue: Value, _ newValue: Value) async -> Seq,
    onValue: @escaping @TreeActor (_ value: Seq.Element) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) where B == Behaviors.Stream<(Value, Value), Seq.Element, Error> {
    self.value = value
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.Stream<(Value, Value), Seq.Element, Error> = Behaviors
      .make(id, input: (Value, Value).self) {
        await behaviorFunc($0.0, $0.1)
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

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with _: RuleContext) throws {
    scope.dispose()
  }

  public mutating func updateRule(
    from other: Self,
    with context: RuleContext
  ) throws {
    if other.value != value {
      let lastValue = value
      value = other.value
      scope.reset()
      callback(scope, context.runtime.behaviorTracker, (lastValue, value))
    }
  }

  public mutating func syncRuntime(with _: RuleContext) throws { }

  // MARK: Private

  private var value: Value
  private let callback: (any BehaviorScoping, BehaviorTracker, (Value, Value)) -> Void
  private let scope: BehaviorStage = .init()
}

extension OnChange {

  /// Register a pre-existing ``Behavior`` to be run when a value is changed.
  ///
  /// - Parameter value: the `Equatable` value whose changes trigger the `action`.
  /// - Parameter id: *Optional*:  A *overriding* ``BehaviorID`` representing the ``Behavior``
  /// created to run the action.
  /// - Parameter runBehavior: The ``Behavior`` run when changes to the value are detected.
  /// - Parameter handler: *Optional*: A handler to run with values created by the ``Behavior``.
  public init(
    _ value: Value,
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
