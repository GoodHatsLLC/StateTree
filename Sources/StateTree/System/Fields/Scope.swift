import TreeActor
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

  @TreeActor
  final class Inner {

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
  public func behavior<B: Behavior>(
    _ id: BehaviorID? = nil,
    _ behavior: B,
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

  @TreeActor
  public func action<Output>(
    _ id: BehaviorID? = nil,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    action: @escaping () async throws -> Output,
    onSuccess success: @escaping (_ value: Output) -> Void,
    onFailure failure: @escaping (_ error: any Error) -> Void
  ) {
    let id = id ?? BehaviorID.meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: "scope-run"
    )
    let behavior = Behaviors.make(id, input: Void.self, subscribe: action)
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: (),
      handler: .init(
        onResult: { result in
          switch result {
          case .success(let value): success(value)
          case .failure(let error): failure(error)
          }
        },
        onCancel: { }
      )
    )
  }

  @TreeActor
  public func action<Output>(
    _ id: BehaviorID? = nil,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    action: @escaping () async -> Output,
    onSuccess success: @escaping @TreeActor (_ value: Output) -> Void
  ) {
    let id = id ?? BehaviorID.meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: "scope-run"
    )
    let behavior = Behaviors.make(id, input: Void.self, subscribe: action)
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: (),
      handler: .init(onSuccess: success, onCancel: { })
    )
  }

  @TreeActor
  public func action<Output>(
    _ id: BehaviorID? = nil,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    action: @escaping Behaviors.Run<Output>.SyncFunc.Throwing,
    onSuccess success: @escaping (_ value: Output) -> Void,
    onFailure failure: @escaping (_ error: any Error) -> Void
  ) {
    let id = id ?? BehaviorID.meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: "scope-run"
    )
    let behavior = Behaviors.make(id, input: Void.self, subscribe: action)
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: (),
      handler: .init(
        onResult: { result in
          switch result {
          case .success(let value): success(value)
          case .failure(let error): failure(error)
          }
        },
        onCancel: { }
      )
    )
  }

  @TreeActor
  public func action<Output>(
    _ id: BehaviorID? = nil,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    action: @escaping () -> Output,
    onSuccess success: @escaping @TreeActor (_ value: Output) -> Void
  ) {
    let id = id ?? BehaviorID.meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: "scope-run"
    )
    let behavior = Behaviors.make(id, input: Void.self, subscribe: action)
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: (),
      handler: .init(onSuccess: success, onCancel: { })
    )
  }

  @TreeActor
  public func run(
    _ id: BehaviorID? = nil,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    action: @escaping () async throws -> Void
  ) {
    let id = id ?? BehaviorID.meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: "scope-run"
    )
    let behavior = Behaviors.make(id, input: Void.self, subscribe: action)
    behavior.run(
      tracker: inner.treeScope?.runtime.behaviorTracker ?? .init(),
      scope: inner.treeScope?.scope ?? Behaviors.Scope.invalid,
      input: ()
    )
  }

}
