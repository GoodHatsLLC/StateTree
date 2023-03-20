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
  @TreeActor
  public func run<Output>(
    _ fileID: String = #fileID,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Make<Void, Output>.Func.NonThrowing
  ) -> ScopedBehavior<Behaviors.Single<Void, Output, Never>> {
    let id = id ?? .meta(fileID: fileID, line: line, column: column, meta: "run")
    return ScopedBehavior(
      behavior: Behaviors.make(id, subscribe: subscribe),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      manager: inner.treeScope?.runtime.behaviorManager ?? .init()
    )
  }

  @TreeActor
  public func run<Output>(
    _ fileID: String = #fileID,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Make<Void, Output>.Func.Throwing
  ) -> ScopedBehavior<Behaviors.Single<Void, Output, any Error>> {
    let id = id ?? .meta(fileID: fileID, line: line, column: column, meta: "run")
    return ScopedBehavior(
      behavior: Behaviors.make(id, subscribe: subscribe),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      manager: inner.treeScope?.runtime.behaviorManager ?? .init()
    )
  }
}

// MARK: Stream
extension Scope {
  @TreeActor
  public func run<Value>(
    _ fileID: String = #fileID,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Stream<Void, Value>.Func
  ) -> ScopedBehavior<Behaviors.Stream<Void, Value>> {
    let id = id ?? .meta(fileID: fileID, line: line, column: column, meta: "run")
    return ScopedBehavior(
      behavior: Behaviors.make(id, subscribe: subscribe),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      manager: inner.treeScope?.runtime.behaviorManager ?? .init()
    )
  }
}
