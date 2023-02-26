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

@TreeActor
@propertyWrapper
public struct Scope: ScopeField {

  // MARK: Lifecycle

  public nonisolated init() { }

  // MARK: Public

  @TreeActor public var wrappedValue: Scope {
    self
  }

  @TreeActor public var projectedValue: Scope {
    self
  }

  public var id: NodeID? {
    inner.treeScope?.id
  }

  public var isActive: Bool {
    inner.treeScope?.scope?.isActive ?? false
  }

  public func resolutions() async -> [BehaviorResolution] {
    await inner.treeScope?.scope?.behaviorResolutions ?? []
  }

  @TreeActor
  public func transaction<T>(_ action: @escaping () throws -> T) rethrows -> T? {
    try inner.treeScope?.runtime.transaction(action)
  }

  @TreeActor
  public func run<T, S: AsyncSequence>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ sequenceAction: @escaping @Sendable () -> S
  ) -> AsyncSequenceBehavior<Void, T>
    where S.Element == T
  {
    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
    let behavior = AsyncSequenceBehavior(id: id) { AnyAsyncSequence<T>(sequenceAction()) }
    guard let underlying = inner.treeScope?.scope
    else {
      runtimeWarning("The scope was not active and could not run the behavior")
      return behavior
    }
    behavior.run(on: underlying, input: ())
    return behavior
  }

  @TreeActor
  public func run<T>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ action: @escaping @Sendable () async -> T
  ) -> AsyncValueBehavior<Void, T> {
    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
    let behavior = AsyncValueBehavior(id: id, action)
    guard let underlying = inner.treeScope?.scope
    else {
      runtimeWarning("The scope was not active and could not run the behavior")
      return behavior
    }
    behavior.run(on: underlying, input: ())
    return behavior
  }

  @TreeActor
  public func run<T>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ action: @escaping @Sendable () async throws -> T
  ) -> AsyncThrowingBehavior<Void, T> {
    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
    let behavior = AsyncThrowingBehavior(id: id, action)
    guard let underlying = inner.treeScope?.scope
    else {
      runtimeWarning("The scope was not active and could not run the behavior")
      return behavior
    }
    behavior.run(on: underlying, input: ())
    return behavior
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
