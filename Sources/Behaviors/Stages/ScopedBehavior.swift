import Disposable
import TreeActor
import Utilities

// MARK: - ScopedBehavior

public struct ScopedBehavior<Behavior: BehaviorType> where Behavior.Input == Void {

  // MARK: Lifecycle

  public init(
    behavior: Behavior,
    scope: any BehaviorScoping,
    manager: BehaviorManager
  ) {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager
    )
  }

  init(
    behavior: AttachableBehavior<Behavior>,
    scope: any BehaviorScoping,
    manager: BehaviorManager
  ) {
    self.id = behavior.id
    self.behavior = behavior
    self.scope = scope
    self.manager = manager
  }

  // MARK: Public

  public let id: BehaviorID

  // MARK: Private

  private let behavior: AttachableBehavior<Behavior>
  private let scope: any BehaviorScoping
  private let manager: BehaviorManager

}

extension ScopedBehavior {

  @discardableResult
  public func fireAndForget() -> Behaviors.Resolution {
    let startable = behavior
      .attach(
        handler: .init()
      )

    Task {
      await startable.start(
        manager: manager,
        input: (),
        scope: scope
      )
    }
    return startable.resolution
  }
}

// MARK: Single
extension ScopedBehavior where Behavior.Handler: SingleHandlerType {

  public var result: Result<Behavior.Value, Behaviors.Cancellation> {
    get async {
      let value = AsyncValue<Result<Behavior.Value, Behaviors.Cancellation>>()
      let startable = behavior
        .attach(handler: .init(
          onSuccess: { val in Task { await value.resolve(.success(val)) } },
          onCancel: { Task { await value.resolve(.failure(Behaviors.cancellation)) } }
        ))
      _ = await startable.start(manager: manager, input: (), scope: scope)
      return await value.value
    }
  }

  @discardableResult
  public func onSuccess(
    _ onSuccess: @escaping @TreeActor (_ value: Behavior.Handler.Value) -> Void,
    onCancel: @escaping @TreeActor () -> Void = { }
  ) async
    -> Behaviors.Resolution
  {
    let startable = behavior
      .attach(handler: .init(onSuccess: onSuccess, onCancel: onCancel))

    return await startable.start(manager: manager, input: (), scope: scope).resolution
  }

  public func get() async throws -> Behavior.Value {
    try await result.get()
  }

}

extension ScopedBehavior where Behavior.Handler: ThrowingSingleHandlerType {
  public var result: Result<Behavior.Value, any Error> {
    get async {
      let value = AsyncValue<Result<Behavior.Value, any Error>>()
      let startable = behavior
        .attach(handler: .init(
          onResult: { val in Task { await value.resolve(val) } },
          onCancel: { Task { await value.resolve(.failure(Behaviors.cancellation)) } }
        ))
      _ = await startable.start(manager: manager, input: (), scope: scope)
      return await value.value
    }
  }

  @discardableResult
  public func onResult(
    _ onResult: @escaping @TreeActor (_ result: Result<Behavior.Handler.Value, Error>) -> Void,
    onCancel: @escaping @TreeActor () -> Void = { }
  ) async
    -> Behaviors.Resolution
  {
    let startable = behavior
      .attach(handler: .init(onResult: onResult, onCancel: onCancel))
    return await startable.start(manager: manager, input: (), scope: scope).resolution
  }

  public func get() async throws -> Behavior.Value {
    try await result.get()
  }
}

extension ScopedBehavior where Behavior.Handler: StreamHandlerType {
  @discardableResult
  public func onValue(
    _ onValue: @escaping @TreeActor (Behavior.Handler.Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onCancel: @escaping @TreeActor () -> Void
  ) async
    -> Behaviors.Resolution
  {
    let startable = behavior
      .attach(handler: .init(onValue: onValue, onFinish: onFinish, onCancel: onCancel))
    return await startable.start(manager: manager, input: (), scope: scope).resolution
  }
}

extension ScopedBehavior where Behavior.Handler: ThrowingStreamHandlerType {
  @discardableResult
  public func onValue(
    _ onValue: @escaping @TreeActor (Behavior.Handler.Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (_ error: any Error) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  ) async
    -> Behaviors.Resolution
  {
    let startable = behavior
      .attach(handler: .init(
        onValue: onValue,
        onFinish: onFinish,
        onFailure: onFailure,
        onCancel: onCancel
      ))
    return await startable.start(manager: manager, input: (), scope: scope).resolution
  }
}
