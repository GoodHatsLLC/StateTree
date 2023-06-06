import TreeActor
@_spi(Implementation) import Behavior

// MARK: - OnReceive

/// Subscribe to and receive values and lifecycle events from an `AsyncSequence` or Combine
/// `Publisher`.
///
/// ```swift
/// OnReceive(someSequence) { value in
///   // ...
/// } onFinish: {
///   // ...
/// } onFailure: { error in
///   // ...
/// }
/// ```
public struct OnReceive<Value: Sendable>: Rules {

  // MARK: Lifecycle

  /// Subscribe to and receive values and lifecycle events from an `AsyncSequence`.
  ///
  /// - Parameter seq: An `AsyncSequence` to subscribe to.
  /// - Parameter id: *Optional:*  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter onValue: A callback fired with values emitted by the `AsyncSequence`.
  /// - Parameter onFinish: *Optional:* A callback run if the `AsyncSequence` completes
  /// successfully.
  /// - Parameter onFailure: *Optional:* A callback run if the `AsyncSequence` fails with an error.
  public init<Seq: AsyncSequence>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ seq: Seq,
    _ id: BehaviorID? = nil,
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) where Seq.Element == Value {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: ""
    )
    let behavior: Behaviors.Stream<Void, Seq.Element, Error> = Behaviors
      .make(id, input: Void.self) {
        seq
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

  // MARK: Public

  public func act(for _: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
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

  public mutating func syncToState(with context: RuleContext) throws {
    scope.reset()
    callback(scope, context.runtime.behaviorTracker)
  }

  // MARK: Private

  private let callback: (any BehaviorScoping, BehaviorTracker) -> Void
  private let scope: BehaviorStage = .init()
}

import Emitter
extension OnReceive {

  /// Subscribe to and receive values and lifecycle events from an `Emitter`.
  ///
  /// - Parameter publisher: A `Emitter` to subscribe to.
  /// - Parameter id: *Optional:*  A ``BehaviorID`` representing the ``Behavior`` created to run the
  /// action.
  /// - Parameter onValue: A callback fired with values emitted by the `Emitter`.
  /// - Parameter onFinish: *Optional:* A callback run if the `Emitter` completes successfully.
  /// - Parameter onFailure: *Optional:* A callback run if the `Emitter` fails with an error.
  @_spi(Implementation)
  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ emitter: some Emitter<Value, Error>,
    _ id: BehaviorID? = nil,
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: ""
    )
    let behavior: Behaviors.Stream<Void, Value, Error> = Behaviors.make(id, input: Void.self) {
      emitter
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
}

#if canImport(Combine)
import Combine

/// Subscribe to and receive values and lifecycle events from a Combine `Publisher`.
///
/// - Parameter publisher: A `Publisher` to subscribe to.
/// - Parameter id: *Optional:*  A ``BehaviorID`` representing the ``Behavior`` created to run the
/// action.
/// - Parameter onValue: A callback fired with values emitted by the `Publisher`.
/// - Parameter onFinish: *Optional:* A callback run if the `Publisher` completes successfully.
/// - Parameter onFailure: *Optional:* A callback run if the `Publisher` fails with an error.
extension OnReceive {
  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ publisher: some Publisher<Value, some Error>,
    _ id: BehaviorID? = nil,
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: ""
    )
    let behavior: Behaviors.Stream<Void, Value, Error> = Behaviors.make(id, input: Void.self) {
      publisher
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
}
#endif
