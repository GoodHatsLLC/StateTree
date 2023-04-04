import Disposable
import TreeActor
import Utilities

// MARK: - Surface

public struct Surface<Behavior: BehaviorEffect>: HandlerSurface {
  public var surface: Surface<Behavior> { self }

  public init(
    input: Behavior.Input,
    behavior: AttachableBehavior<Behavior>,
    scope: any BehaviorScoping,
    manager: BehaviorManager
  ) {
    self.id = behavior.id
    self.input = input
    self.behavior = behavior
    self.scope = scope
    self.manager = manager
  }

  let id: BehaviorID
  let input: Behavior.Input
  let behavior: AttachableBehavior<Behavior>
  let scope: any BehaviorScoping
  let manager: BehaviorManager
}

// MARK: - HandlerSurface

public protocol HandlerSurface<Behavior> {
  associatedtype Behavior: BehaviorEffect
  var surface: Surface<Behavior> { get }

}

extension HandlerSurface {

  @discardableResult
  public func fireAndForget() -> Behaviors.Resolution {
    let startable = surface.behavior
      .attach(
        handler: .init()
      )
    let (resolution, finalizer) = startable.start(
      manager: surface.manager,
      input: surface.input,
      scope: surface.scope
    )
    if let finalizer {
      Task {
        await finalizer()
      }
    }
    return resolution
  }
}

extension HandlerSurface where Behavior.Handler: SingleHandlerType, Behavior.Failure == Never {
  @_spi(Implementation) public var value: Behavior.Output? {
    var value: Behavior.Output?
    let startable = surface.behavior
      .attach(handler: .init(
        onSuccess: { val in
          value = val
        },
        onCancel: {
          value = nil
        }
      ))
    let (_, finalizer) = startable.start(
      manager: surface.manager,
      input: surface.input,
      scope: surface.scope
    )
    if let finalizer {
      Task {
        _ = await finalizer()
      }
    }
    return value
  }

  @discardableResult
  public func onSuccess(
    _ onSuccess: @escaping (_ value: Behavior.Handler.Output) -> Void,
    onCancel: @escaping () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let startable = surface.behavior
      .attach(handler: .init(onSuccess: onSuccess, onCancel: onCancel))
    let (resolution, finalizer) = startable.start(
      manager: surface.manager,
      input: surface.input,
      scope: surface.scope
    )
    if let finalizer {
      Task {
        _ = await finalizer()
      }
    }
    return resolution
  }

}

extension HandlerSurface where Behavior.Handler: SingleHandlerType, Behavior.Failure == any Error {

  @discardableResult
  public func onResult(
    _ onResult: @escaping (_ result: Result<Behavior.Output, Error>) -> Void,
    onCancel: @escaping () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let startable = surface.behavior
      .attach(handler: .init(onResult: onResult, onCancel: onCancel))
    let (resolution, finalizer) = startable.start(
      manager: surface.manager,
      input: surface.input,
      scope: surface.scope
    )
    if let finalizer {
      Task {
        _ = await finalizer()
      }
    }
    return resolution
  }
}

extension HandlerSurface where Behavior.Handler: StreamHandlerType {
  @discardableResult
  public func onValue(
    _ onValue: @escaping (_ value: Behavior.Handler.Output) -> Void,
    onFinish: @escaping () -> Void,
    onFailure: @escaping (_ error: any Error) -> Void,
    onCancel: @escaping () -> Void
  )
    -> Behaviors.Resolution
  {
    let startable = surface.behavior
      .attach(handler: .init(
        onValue: onValue,
        onFinish: onFinish,
        onFailure: onFailure,
        onCancel: onCancel
      ))
    let (resolution, finalizer) = startable.start(
      manager: surface.manager,
      input: surface.input,
      scope: surface.scope
    )
    if let finalizer {
      Task {
        _ = await finalizer()
      }
    }
    return resolution
  }
}
