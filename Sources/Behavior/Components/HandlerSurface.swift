import Disposable
import TreeActor
import Utilities

// MARK: - Surface

public struct Surface<B: Behavior>: HandlerSurface {
  public var surface: Surface<B> { self }

  public init(
    input: B.Input,
    behavior: AttachableBehavior<B>,
    scope: any BehaviorScoping,
    tracker: BehaviorTracker
  ) {
    self.id = behavior.id
    self.input = input
    self.behavior = behavior
    self.scope = scope
    self.tracker = tracker
  }

  let id: BehaviorID
  let input: B.Input
  let behavior: AttachableBehavior<B>
  let scope: any BehaviorScoping
  let tracker: BehaviorTracker
}

// MARK: - HandlerSurface

public protocol HandlerSurface<B> {
  associatedtype B: Behavior
  var surface: Surface<B> { get }

}

extension HandlerSurface {

  @discardableResult
  public func fireAndForget() -> Behaviors.Resolution {
    let startable = surface.behavior
      .attach(
        handler: .init()
      )
    let (resolution, finalizer) = startable.start(
      tracker: surface.tracker,
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

extension HandlerSurface where B.Handler: SingleHandlerType, B.Failure == Never {
  @_spi(Implementation) public var value: B.Output? {
    var value: B.Output?
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
      tracker: surface.tracker,
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
    _ onSuccess: @escaping (_ value: B.Handler.Output) -> Void,
    onCancel: @escaping () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let startable = surface.behavior
      .attach(handler: .init(onSuccess: onSuccess, onCancel: onCancel))
    let (resolution, finalizer) = startable.start(
      tracker: surface.tracker,
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

extension HandlerSurface where B.Handler: SingleHandlerType, B.Failure == any Error {

  @discardableResult
  public func onResult(
    _ onResult: @escaping (_ result: Result<B.Output, Error>) -> Void,
    onCancel: @escaping () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let startable = surface.behavior
      .attach(handler: .init(onResult: onResult, onCancel: onCancel))
    let (resolution, finalizer) = startable.start(
      tracker: surface.tracker,
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

extension HandlerSurface where B.Handler: StreamHandlerType {
  @discardableResult
  public func onValue(
    _ onValue: @escaping (_ value: B.Handler.Output) -> Void,
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
      tracker: surface.tracker,
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
