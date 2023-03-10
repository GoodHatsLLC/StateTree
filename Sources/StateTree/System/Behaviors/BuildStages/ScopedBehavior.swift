import Emitter

// MARK: - ScopedBehavior

public struct ScopedBehavior<Behavior: BehaviorType> where Behavior.Input == Void {

  // MARK: Lifecycle

  init(
    behavior: AttachableBehavior<Behavior>,
    scope: any Scoping,
    manager: BehaviorManager
  ) {
    self.id = behavior.id
    self.behavior = behavior
    self.scope = scope
    self.manager = manager
  }

  // MARK: Public

  public let id: BehaviorID
  private let behavior: AttachableBehavior<Behavior>
  private let scope: any Scoping
  private let manager: BehaviorManager

}

extension ScopedBehavior {

  @discardableResult
  public func fireAndForget() -> Behaviors.Resolution {
    let resolution = Behaviors.Resolution(id: id)
    Task {
      let active = await behavior
        .attach(
          handler: Behavior.Handler { _ in }
        )
        .start(
          manager: manager,
          input: (),
          resolution: resolution
        )
      scope.own(active)
    }
    return resolution
  }
}

// MARK: Single
extension ScopedBehavior where Behavior.Event: BehaviorSingleEventType {

  public func get() async throws -> Behavior.Event.Success {
    let value = AsyncValue<Behavior.Event>()
    let active = await behavior
      .attach(handler: Behavior.Handler {
        value.resolve($0)
      })
      .start(manager: manager, input: ())
    scope.own(active)
    let event = await value.value
    switch event.concrete {
    case .cancelled: throw BehaviorCancellationError()
    case .failed(let error): throw error
    case .finished(let success): return success
    }
  }
}

extension ScopedBehavior where Behavior.Event: BehaviorSingleEventType,
  Behavior.Event.Failure == Never
{

  public var value: Behavior.Event.Success? {
    get async {
      let value = AsyncValue<Behavior.Event>()
      let active = await behavior
        .attach(handler: Behavior.Handler {
          value.resolve($0)
        })
        .start(manager: manager, input: ())
      scope.own(active)
      let event = await value.value
      switch event.concrete {
      case .cancelled: return nil
      case .finished(let success): return success
      }
    }
  }

  @TreeActor
  @discardableResult
  public func onSuccess(
    _ success: @escaping @TreeActor (_ value: Behavior.Event.Success) -> Void,
    onCancel: @escaping @TreeActor () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let handler = Behavior.Handler { event in
      switch event.concrete {
      case .finished(let value):
        success(value)
      case .cancelled:
        onCancel()
      }
    }
    let active = behavior
      .attach(handler: handler)
      .start(manager: manager, input: ())
    scope.own(active)
    return active.resolution
  }

}

extension ScopedBehavior where Behavior.Event: BehaviorSingleEventType {
  @TreeActor
  @discardableResult
  public func onResult(
    _ onResult: @escaping @TreeActor (_ result: Result<
      Behavior.Event.Success,
      Behavior.Event.Failure
    >) -> Void,
    onCancel: @escaping @TreeActor () -> Void = { }
  )
    -> Behaviors.Resolution
  {
    let handler = Behavior.Handler { event in
      switch event.concrete {
      case .finished(let value):
        onResult(.success(value))
      case .cancelled:
        onCancel()
      case .failed(let error):
        onResult(.failure(error))
      }
    }
    let active = behavior
      .attach(handler: handler)
      .start(manager: manager, input: ())
    scope.own(active)
    return active.resolution
  }
}

// MARK: Stream

extension ScopedBehavior where Behavior.Event: BehaviorStreamEventType {

  public var values: AnyAsyncSequence<Behavior.Event.Output> {
    let subject = PublishSubject<Behavior.Event.Output>()
    Task {
      let handler = Behavior.Handler { event in
        switch event.concrete {
        case .cancelled,
             .finished:
          subject.emit(.finished)
        case .emission(let output):
          subject.emit(.value(output))
        case .failed(let error):
          subject.emit(.failed(error))
        }
      }
      let active = await behavior
        .attach(handler: handler)
        .start(manager: manager, input: ())
      scope.own(active)
    }
    return AnyAsyncSequence(subject.values)
  }

  @TreeActor
  public func onOutput(
    _ onOutput: @escaping @TreeActor (_ value: Behavior.Event.Output) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFail: @escaping @TreeActor (_ error: Behavior.Event.Failure) -> Void = { _ in }
  )
    -> Behaviors.Resolution
  {
    let handler = Behavior.Handler { event in
      switch event.concrete {
      case .emission(let output):
        onOutput(output)
      case .finished:
        onFinish()
      case .cancelled:
        onFinish()
      case .failed(let error):
        onFail(error)
      }
    }
    let active = behavior
      .attach(handler: handler)
      .start(manager: manager, input: ())
    scope.own(active)
    return active.resolution
  }
}
