import Behaviors

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

  @TreeActor
  public func transaction<T>(_ action: @escaping () throws -> T) rethrows -> T? {
    try inner.treeScope?.runtime.transaction(action)
  }

//
//  @TreeActor
//  public func run<T>(
//    fileID: String = #fileID,
//    line: Int = #line,
//    column: Int = #column,
//    _ id: BehaviorID? = nil,
//    action: @escaping @Sendable () async -> T
//  ) -> ScopedBehavior<Behaviors.AlwaysSingle<Void, T>> {
//    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
//    let behavior = Behavior<Void, Never, T, Never>.single(id: id) { _, send in
//      await send(.finished(action()))
//    }
//    guard
//      let scope = inner.treeScope?.scope,
//      let manager = inner.treeScope?.runtime.behaviorManager
//    else {
//      runtimeWarning(
//        "Attempting to run a behavior with an unattached scope. This will always fail."
//      )
//      assertionFailure(
//        "Attempting to run a behavior with an unattached scope. This will always fail."
//      )
//      return ScopedBehavior(
//        behavior: AttachableBehavior(behavior: behavior),
//        scope: Scope.invalid,
//        manager: .init()
//      )
//    }
//    let attachable = AttachableBehavior(behavior: behavior)
//    return ScopedBehavior(
//      behavior: attachable,
//      scope: scope,
//      manager: manager
//    )
//  }
//
//  @TreeActor
//  public func run<T>(
//    fileID: String = #fileID,
//    line: Int = #line,
//    column: Int = #column,
//    _ id: BehaviorID? = nil,
//    action: @escaping @Sendable () async throws -> T
//  ) -> ScopedBehavior<Behaviors.FailableSingle<Void, T>> {
//    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
//    let behavior = Behavior<Void, Never, T, Error>.failableSingle(id: id) { _, send in
//      do {
//        try await send(.finished(action()))
//      } catch {
//        await send(.failed(error))
//      }
//    }
//    guard
//      let scope = inner.treeScope?.scope,
//      let manager = inner.treeScope?.runtime.behaviorManager
//    else {
//      runtimeWarning(
//        "Attempting to run a behavior with an unattached scope. This will always fail."
//      )
//      assertionFailure(
//        "Attempting to run a behavior with an unattached scope. This will always fail."
//      )
//      return ScopedBehavior(
//        behavior: AttachableBehavior(behavior: behavior),
//        scope: Scope.invalid,
//        manager: .init()
//      )
//    }
//    let attachable = AttachableBehavior(behavior: behavior)
//    return ScopedBehavior(
//      behavior: attachable,
//      scope: scope,
//      manager: manager
//    )
//  }
//
//  @TreeActor
//  public func run<T, Seq: AsyncSequence>(
//    fileID: String = #fileID,
//    line: Int = #line,
//    column: Int = #column,
//    _ id: BehaviorID? = nil,
//    action: @escaping @Sendable () throws -> Seq
//  ) -> ScopedBehavior<Behaviors.Stream<Void, T, Error>>
//    where Seq.Element == T
//  {
//    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
//
//    let producerFunc: Behavior<Void, T, Never, Error>.StreamProducerFunc = { _, send in
//      let seq = try action()
//      Task {
//        do {
//          for try await value in seq {
//            await send(.emission(value))
//          }
//          await send(.finished)
//        } catch is CancellationError {
//          await send(.cancelled)
//        } catch {
//          await send(.failed(error))
//        }
//      }
//    }
//
//    let behavior = Behavior<Void, T, Never, Error>
//      .stream(id: id, eventProducer: producerFunc)
//    guard
//      let scope = inner.treeScope?.scope,
//      let manager = inner.treeScope?.runtime.behaviorManager
//    else {
//      runtimeWarning(
//        "Attempting to run a behavior with an unattached scope. This will always fail."
//      )
//      assertionFailure(
//        "Attempting to run a behavior with an unattached scope. This will always fail."
//      )
//      return ScopedBehavior(
//        behavior: AttachableBehavior(behavior: behavior),
//        scope: Scope.invalid,
//        manager: .init()
//      )
//    }
//    let attachable = AttachableBehavior(behavior: behavior)
//    return ScopedBehavior(
//      behavior: attachable,
//      scope: scope,
//      manager: manager
//    )
//  }

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
