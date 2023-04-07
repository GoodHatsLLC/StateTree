@_spi(Implementation) import Behavior
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

  /// Run a `Behavior`.
  @TreeActor
  public func run<B: Behavior>(
    _ behavior: B,
    _ id: BehaviorID? = nil,
    input: B.Input,
    handler: B.Handler? = nil
  ) {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    if let handler {
      behavior.run(
        tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
        scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
        input: input,
        handler: handler
      )
    } else {
      behavior.run(
        tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
        scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
        input: input
      )
    }
  }

  /// Run a sequence-output `Behavior`.
  @TreeActor
  public func run<B: Behavior>(
    _ behavior: B,
    _ id: BehaviorID? = nil,
    input: B.Input,
    onValue: @escaping @TreeActor (_ value: B.Output) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (_ failure: Error) -> Void
  ) where B.Handler == Behaviors.StreamHandler<Asynchronous, B.Output, Error> {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: input,
      handler: .init(onValue: onValue, onFinish: onFinish, onFailure: onFailure, onCancel: { })
    )
  }

  /// Run an asynchronous throwing single-output `Behavior`.
  @TreeActor
  public func run<B: Behavior>(
    _ behavior: B,
    _ id: BehaviorID? = nil,
    input: B.Input,
    onResult: @escaping @TreeActor (_ result: Result<B.Output, Error>) -> Void
  ) where B.Handler == Behaviors.SingleHandler<Asynchronous, B.Output, Error> {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: input,
      handler: .init(onResult: onResult, onCancel: { })
    )
  }

  /// Run an asynchronous non-failing single-output `Behavior`.
  @TreeActor
  public func run<B: Behavior>(
    _ behavior: B,
    _ id: BehaviorID? = nil,
    input: B.Input,
    onSuccess: @escaping @TreeActor (_ value: B.Output) -> Void
  ) where B.Handler == Behaviors.SingleHandler<Asynchronous, B.Output, Never> {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: input,
      handler: .init(onSuccess: onSuccess, onCancel: { })
    )
  }

  /// Run a synchronous throwing single-output `Behavior`.
  @TreeActor
  public func run<B: Behavior>(
    _ behavior: B,
    _ id: BehaviorID? = nil,
    input: B.Input,
    onResult: @escaping @TreeActor (_ result: Result<B.Output, Error>) -> Void
  ) where B.Handler == Behaviors.SingleHandler<Synchronous, B.Output, Error> {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: input,
      handler: .init(onResult: onResult, onCancel: { })
    )
  }

  /// Run a synchronous non-failing single-output `Behavior`.
  @TreeActor
  public func run<B: Behavior>(
    _ behavior: B,
    _ id: BehaviorID? = nil,
    input: B.Input,
    onSuccess: @escaping @TreeActor (_ value: B.Output) -> Void
  ) where B.Handler == Behaviors.SingleHandler<Synchronous, B.Output, Never> {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: input,
      handler: .init(onSuccess: onSuccess, onCancel: { })
    )
  }

  /// Create and run a `SyncSingle<Void, Void, Never>` `Behavior`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped out in tests.
  /// - Parameter subscribe: the action which runs any of the Behavior's side effects.
  @TreeActor
  public func run(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Make<Void, Void>.SyncFunc.NonThrowing
  ) {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "run")
    let behavior = Behaviors.make(id, input: Void.self, subscribe: subscribe)
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: ()
    )
  }

  /// Create and run a `AsyncSingle<Void, Void, Never>` `Behavior`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped out in tests.
  /// - Parameter subscribe: the action which runs any of the Behavior's side effects.
  @TreeActor
  public func run(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Make<Void, Void>.AsyncFunc.NonThrowing
  ) {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "run")
    let behavior = Behaviors.make(id, input: Void.self, subscribe: subscribe)
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: ()
    )
  }
}
