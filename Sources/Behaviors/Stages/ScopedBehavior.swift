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
  ) where Behavior: AsyncBehaviorType {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager
    )
  }

  @TreeActor
  public init(
    behavior: Behavior,
    scope: any BehaviorScoping,
    manager: BehaviorManager
  ) where Behavior: SyncBehaviorType {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager
    )
  }

  public init(
    behavior: Behavior,
    scope: any BehaviorScoping,
    manager: BehaviorManager
  ) where Behavior: StreamBehaviorType {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager
    )
  }

  fileprivate init(
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
    let (resolution, finalizer) = startable.start(
      manager: manager,
      input: (),
      scope: scope
    )
    if let finalizer {
      Task {
        await finalizer()
      }
    }
    return resolution
  }
}

extension ScopedBehavior where Behavior.Handler: SingleHandlerType, Behavior: SyncBehaviorType {
  public var result: Result<Behavior.Output, Behaviors.Cancellation> {
    var result: Result<Behavior.Output, Behaviors.Cancellation>?
    let startable = behavior
      .attach(handler: .init(
        onSuccess: { val in
          result = .success(val)
        },
        onCancel: {
          result = .failure(.init())
        }
      ))
    let (_, finalizer) = startable.start(
      manager: manager,
      input: (),
      scope: scope
    )
    if let finalizer {
      Task { await finalizer() }
    }
    assert(result != nil)
    return result ?? .failure(.init())
  }

  @discardableResult
  public func onSuccess(
    _ onSuccess: @escaping (_ value: Behavior.Handler.Output) -> Void,
    onCancel: @escaping () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let startable = behavior
      .attach(handler: .init(onSuccess: onSuccess, onCancel: onCancel))
    let (resolution, finalizer) = startable.start(
      manager: manager,
      input: (),
      scope: scope
    )
    Task {
      if let finalizer {
        _ = await finalizer()
      }
    }
    return resolution
  }

}

extension ScopedBehavior where Behavior.Handler: ThrowingSingleHandlerType,
  Behavior: SyncBehaviorType
{

  public var result: Result<Behavior.Output, Error> {
    var result: Result<Behavior.Output, Error>?
    let startable = behavior
      .attach(handler: .init(
        onResult: { res in
          result = res
        },
        onCancel: {
          result = .failure(Behaviors.Cancellation())
        }
      ))
    let (_, finalizer) = startable.start(
      manager: manager,
      input: (),
      scope: scope
    )
    Task { await finalizer?() }
    assert(result != nil)
    return result ?? .failure(Behaviors.Cancellation())
  }

  @discardableResult
  public func onResult(
    _ onResult: @escaping (_ result: Result<Behavior.Output, Error>) -> Void,
    onCancel: @escaping () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let startable = behavior
      .attach(handler: .init(onResult: onResult, onCancel: onCancel))
    let (resolution, finalizer) = startable.start(
      manager: manager,
      input: (),
      scope: scope
    )
    Task {
      if let finalizer {
        _ = await finalizer()
      }
    }
    return resolution
  }
}

// MARK: Single
extension ScopedBehavior where Behavior.Handler: SingleHandlerType, Behavior: AsyncBehaviorType {

  public var result: Result<Behavior.Output, Behaviors.Cancellation> {
    get async {
      let value = Async.Value<Result<Behavior.Output, Behaviors.Cancellation>>()
      scope.own(AnyDisposable {
        Task.detached {
          await value.resolve(.failure(Behaviors.cancellation))
        }
      })
      let startable = behavior
        .attach(handler: .init(
          onSuccess: { val in
            Task {
              await value.resolve(.success(val))
            }
          },
          onCancel: {
            Task {
              await value.resolve(.failure(Behaviors.cancellation))
            }
          }
        ))
      let (_, finalizer) = startable.start(
        manager: manager,
        input: (),
        scope: scope
      )
      if let finalizer {
        _ = await finalizer()
      }
      return await value.value
    }
  }

  @discardableResult
  public func onSuccess(
    _ onSuccess: @escaping (_ value: Behavior.Handler.Output) -> Void,
    onCancel: @escaping () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let startable = behavior
      .attach(handler: .init(onSuccess: onSuccess, onCancel: onCancel))
    let (resolution, finalizer) = startable.start(
      manager: manager,
      input: (),
      scope: scope
    )
    Task {
      if let finalizer {
        _ = await finalizer()
      }
    }
    return resolution
  }

}

extension ScopedBehavior where Behavior.Handler: ThrowingSingleHandlerType,
  Behavior: AsyncBehaviorType
{
  public var result: Result<Behavior.Output, Error> {
    get async {
      let value = Async.Value<Result<Behavior.Output, Error>>()
      scope.own(AnyDisposable {
        Task.detached {
          await value.resolve(.failure(Behaviors.cancellation))
        }
      })
      let startable = behavior
        .attach(handler: .init(
          onResult: { val in
            Task {
              await value.resolve(val.mapError { $0 })
            }
          },
          onCancel: {
            Task {
              await value.resolve(.failure(Behaviors.cancellation))
            }
          }
        ))
      let (_, finalizer) = startable.start(
        manager: manager,
        input: (),
        scope: scope
      )
      if let finalizer {
        _ = await finalizer()
      }
      return await value.value
    }
  }

  @discardableResult
  public func onResult(
    _ onResult: @escaping (_ result: Result<Behavior.Output, Error>) -> Void,
    onCancel: @escaping () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let startable = behavior
      .attach(handler: .init(onResult: onResult, onCancel: onCancel))
    let (resolution, finalizer) = startable.start(
      manager: manager,
      input: (),
      scope: scope
    )
    Task {
      if let finalizer {
        _ = await finalizer()
      }
    }
    return resolution
  }
}

extension ScopedBehavior where Behavior.Handler: StreamHandlerType {
  @discardableResult
  public func onValue(
    _ onValue: @escaping (_ value: Behavior.Handler.Output) -> Void,
    onFinish: @escaping () -> Void,
    onFailure: @escaping (_ error: any Error) -> Void,
    onCancel: @escaping () -> Void
  )
    -> Behaviors.Resolution
  {
    let startable = behavior
      .attach(handler: .init(
        onValue: onValue,
        onFinish: onFinish,
        onFailure: onFailure,
        onCancel: onCancel
      ))
    let (resolution, finalizer) = startable.start(
      manager: manager,
      input: (),
      scope: scope
    )
    Task {
      if let finalizer {
        _ = await finalizer()
      }
    }
    return resolution
  }
}
