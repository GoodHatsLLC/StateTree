@_spi(Implementation) import Behaviors
import Utilities

// MARK: - ScopeField

protocol ScopeField {
  var inner: Scope.Inner { get }
}

// MARK: - TreeScope

@TreeActor
struct TreeScope {
  let runtime: Runtime
  let id: NodeID
  var scope: AnyScope? { try? runtime.getScope(for: id) }
}

// MARK: - Scope

@propertyWrapper
public struct Scope: ScopeField {

  // MARK: Lifecycle

  public nonisolated init() { }

  // MARK: Public

  public var wrappedValue: Scope {
    self
  }

  public var projectedValue: Scope {
    self
  }

  @TreeActor public var id: NodeID? {
    inner.treeScope?.id
  }

  @TreeActor public var isActive: Bool {
    inner.treeScope?.scope?.isActive ?? false
  }

  @TreeActor
  public func transaction<T>(_ action: @escaping @TreeActor () throws -> T) rethrows -> T? {
    try inner.treeScope?.runtime.transaction(action)
  }

  // MARK: Internal

  @TreeActor final class Inner {

    // MARK: Lifecycle

    nonisolated init() { }

    // MARK: Internal

    var treeScope: TreeScope?
  }

  static let invalid = NeverScope()

  let inner = Inner()

}

// MARK: Single
extension Scope {

  /// Run the passed `BehaviorType`
  ///
  /// Create a `BehaviorType` emitting a single of `Output` value or an `any Error` from a
  /// synchronous closure.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped out in tests.
  /// - Parameter subscribe: the action which runs any of the Behavior's side effects and
  /// synchronously returns the `Output` value.
  @TreeActor
  public func run<B: SyncBehaviorType>(
    _ behavior: B,
    input: B.Input
  ) -> ScopedBehavior<B> {
    return ScopedBehavior<B>(
      behavior: behavior,
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      manager: inner.treeScope?.runtime.behaviorManager ?? .init(),
      input: input
    )
  }

  /// Create and run a `SyncSingle<Void, Output, Error>` `BehaviorType`.
  ///
  /// Create a `BehaviorType` emitting a single of `Output` value or an `any Error` from a
  /// synchronous closure.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped out in tests.
  /// - Parameter subscribe: the action which runs any of the Behavior's side effects and
  /// synchronously returns the `Output` value.
  @TreeActor
  public func run<Output>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Make<Void, Output>.AsyncFunc.NonThrowing
  ) -> ScopedBehavior<Behaviors.AsyncSingle<Void, Output, Never>> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "run")
    return ScopedBehavior(
      behavior: Behaviors.make(id, input: Void.self, subscribe: subscribe),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      manager: inner.treeScope?.runtime.behaviorManager ?? .init(),
      input: ()
    )
  }

  /// Create and run a `AsyncSingle<Void, Output, Error>` `BehaviorType`.
  ///
  /// Create a `BehaviorType` emitting a single of `Output` value or an `any Error` from a
  /// synchronous closure.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created behavior — with which it can be
  /// swapped out in tests.
  /// - Parameter subscribe: the action which runs any of the Behavior's side effects and returns
  /// the `Output` value.
  @TreeActor
  public func run<Output>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Make<Void, Output>.AsyncFunc.Throwing
  ) -> ScopedBehavior<Behaviors.AsyncSingle<Void, Output, any Error>> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "run")
    return ScopedBehavior(
      behavior: Behaviors.make(id, input: Void.self, subscribe: subscribe),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      manager: inner.treeScope?.runtime.behaviorManager ?? .init(),
      input: ()
    )
  }
}

// MARK: Stream
extension Scope {
  /// Create and run a `Stream<Void, Output>` `BehaviorType`.
  ///
  /// Create a `BehaviorType` emitting a stream of `Output` values, and potentially terminating with
  /// `any Error`,
  /// from a synchronous closure returning an `AsyncSequence`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created behavior — with which it can be
  /// swapped out in tests.
  /// - Parameter subscribe: the action which runs any of the Behavior's side effects and returns
  /// the `Output` emitting `AsyncSequence`.
  @TreeActor
  public func run<Output>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Make<Void, Output>.StreamFunc
  ) -> ScopedBehavior<Behaviors.Stream<Void, Output>> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "run")
    return ScopedBehavior(
      behavior: Behaviors.make(id, input: Void.self, subscribe: subscribe),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      manager: inner.treeScope?.runtime.behaviorManager ?? .init(),
      input: ()
    )
  }
}
