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
    let attached = behavior
      .attach(
        handler: .init()
      )
    let startable = attached.start(
      manager: manager,
      input: (),
      scope: scope
    )
    Task {
      await startable()
    }
    return attached.resolution
  }
}

// MARK: Single
extension ScopedBehavior where Behavior.Handler: SingleHandlerType {

  public var result: Result<Behavior.Output, Behaviors.Cancellation> {
    get async {
      let value = Async.Value<Result<Behavior.Output, Behaviors.Cancellation>>()
      let attached = behavior
        .attach(handler: .init(
          onSuccess: { val in Task { await value.resolve(.success(val)) } },
          onCancel: { Task { await value.resolve(.failure(Behaviors.cancellation)) } }
        ))
      let startable = attached.start(
        manager: manager,
        input: (),
        scope: scope
      )
      Task {
        await startable()
      }
      return await value.value
    }
  }

  @discardableResult
  public func onSuccess(
    _ onSuccess: @escaping @TreeActor (_ value: Behavior.Handler.Output) -> Void,
    onCancel: @escaping @TreeActor () -> Void = { }
  ) async
    -> Behaviors.Resolution
  {
    let attached = behavior
      .attach(handler: .init(onSuccess: onSuccess, onCancel: onCancel))
    let startable = attached.start(
      manager: manager,
      input: (),
      scope: scope
    )
    scope.own(await startable())
    return attached.resolution
  }

  public func get() async throws -> Behavior.Output {
    try await result.get()
  }

}

extension ScopedBehavior where Behavior.Handler: ThrowingSingleHandlerType {
  public var result: Result<Behavior.Output, Error> {
    get async {
      let value = Async.Value<Result<Behavior.Output, Error>>()
      let attached = behavior
        .attach(handler: .init(
          onResult: { val in Task { await value.resolve(val.mapError { $0 }) } },
          onCancel: { Task { await value.resolve(.failure(Behaviors.cancellation)) } }
        ))
      let startable = attached.start(
        manager: manager,
        input: (),
        scope: scope
      )
      Task { await startable() }
      return await value.value
    }
  }

  @discardableResult
  public func onResult(
    _ onResult: @escaping @TreeActor (_ result: Result<Behavior.Output, Error>) -> Void,
    onCancel: @escaping @TreeActor () -> Void = { }
  ) async
    -> Behaviors.Resolution
  {
    let attached = behavior
      .attach(handler: .init(onResult: onResult, onCancel: onCancel))
    let startable = attached.start(
      manager: manager,
      input: (),
      scope: scope
    )
    scope.own(await startable())
    return attached.resolution
  }

  public func get() async throws -> Behavior.Output {
    try await result.get()
  }
}

extension ScopedBehavior where Behavior.Handler: StreamHandlerType {
  @discardableResult
  public func onValue(
    _ onValue: @escaping @TreeActor (Behavior.Output) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onCancel: @escaping @TreeActor () -> Void
  ) async
    -> Behaviors.Resolution
  {
    let attached = behavior
      .attach(handler: .init(onValue: onValue, onFinish: onFinish, onCancel: onCancel))
    let startable = attached.start(
      manager: manager,
      input: (),
      scope: scope
    )
    scope.own(await startable())
    return attached.resolution
  }
}

extension ScopedBehavior where Behavior.Handler: ThrowingStreamHandlerType {
  @discardableResult
  public func onValue(
    _ onValue: @escaping @TreeActor (Behavior.Handler.Output) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (_ error: any Error) -> Void,
    onCancel: @escaping @TreeActor () -> Void
  ) async
    -> Behaviors.Resolution
  {
    let attached = behavior
      .attach(handler: .init(
        onValue: onValue,
        onFinish: onFinish,
        onFailure: onFailure,
        onCancel: onCancel
      ))
    let startable = attached.start(
      manager: manager,
      input: (),
      scope: scope
    )
    scope.own(await startable())
    return attached.resolution
  }
}
