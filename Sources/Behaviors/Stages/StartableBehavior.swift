import Disposable
import TreeActor
import Utilities

public struct StartableBehavior<Input> {

  // MARK: Lifecycle

  @TreeActor
  public init<B: Behavior>(
    behavior proposedBehavior: B,
    tracker: BehaviorTracker
  ) where B.Input == Input {
    switch proposedBehavior.switchType {
    case .async(let asyncB):
      self = .init(behavior: asyncB, handler: .init(), tracker: tracker)
    case .sync(let syncB):
      self = .init(behavior: syncB, handler: .init(), tracker: tracker)
    case .stream(let streamB):
      self = .init(behavior: streamB, handler: .init(), tracker: tracker)
    }
  }

  @TreeActor
  public init<B: Behavior>(
    behavior proposedBehavior: B,
    handler: B.Handler,
    tracker: BehaviorTracker
  ) where B.Input == Input {
    switch proposedBehavior.switchType {
    case .async(let asyncB):
      let handler = handler as? Behaviors.SingleHandler<Asynchronous, B.Output, B.Failure> ?? {
        assertionFailure("bad handler type")
        return .init()
      }()
      self = .init(asyncBehavior: asyncB, handler: handler, tracker: tracker)
    case .sync(let syncB):
      let handler = handler as? Behaviors.SingleHandler<Synchronous, B.Output, B.Failure> ?? {
        assertionFailure("bad handler type")
        return .init()
      }()
      self = .init(syncBehavior: syncB, handler: handler, tracker: tracker)
    case .stream(let streamB):
      let handler = handler as? Behaviors.StreamHandler<Asynchronous, B.Output, B.Failure> ?? {
        assertionFailure("bad handler type")
        return .init()
      }()
      self = .init(streamBehavior: streamB, handler: handler, tracker: tracker)
    }
  }

  public init<Behavior: AsyncBehaviorType>(
    asyncBehavior proposedBehavior: Behavior,
    handler: Behavior.Handler,
    tracker: BehaviorTracker
  ) where Behavior.Input == Input {
    let id = proposedBehavior.id
    let handler = handler
    self.id = id
    self.starter = { tracker, input, scope in
      var mutBehavior = proposedBehavior
      tracker
        .intercept(
          behavior: &mutBehavior,
          input: input
        )
      let finalBehavior = mutBehavior

      guard scope.canOwn()
      else {
        handler.cancel()
        // If the scope itself can't own the behavior, return early without a finalizer.
        let resolution = Behaviors.Resolution(
          id: id,
          tracker: tracker,
          value: .init(id: id, state: .cancelled)
        )

        return (resolution: resolution, finalizer: nil)
      }
      // For an asynchronous behaviors:
      // - we can not start immediately
      // - we return a finalizer that does so asynchronously.
      let resolution = Behaviors.Resolution(
        id: id,
        tracker: tracker
      )
      return (
        resolution: resolution,
        finalizer: {
          let task = Disposables.Task.detached {
            let behavior = await ActivatedBehavior(
              behavior: finalBehavior,
              input: input,
              handler: handler,
              resolution: resolution
            )
            scope.own(behavior)
            await resolution.markStarted()
            return await resolution.value
          } onDispose: {
            Task.detached {
              await resolution.resolve(to: .cancelled) {
                handler.cancel()
              }
            }
          }
          scope.own(task)
          return await resolution.value
        }
      )
    }
  }

  @TreeActor
  public init<Behavior: SyncBehaviorType>(
    syncBehavior proposedBehavior: Behavior,
    handler: Behavior.Handler,
    tracker: BehaviorTracker
  ) where Behavior.Input == Input {
    let id = proposedBehavior.id
    let handler = handler
    self.id = id
    self.starter = { tracker, input, scope in
      var mutBehavior = proposedBehavior
      tracker
        .intercept(
          behavior: &mutBehavior,
          input: input
        )
      let finalBehavior = mutBehavior

      guard scope.canOwn()
      else {
        handler.cancel()
        // If the scope itself can't own the behavior, return early without a finalizer.
        let resolution = Behaviors.Resolution(
          id: id,
          tracker: tracker,
          value: .init(id: id, state: .cancelled)
        )

        return (resolution: resolution, finalizer: nil)
      }
      // For a synchronous behavior, we can start and resolve it
      // immediately and synchronously — and return a stub finalizer.
      let resolution = Behaviors.Resolution(id: id, tracker: tracker)
      let activated = ActivatedBehavior(
        behavior: finalBehavior,
        input: input,
        handler: handler,
        resolution: resolution
      )
      scope.own(activated)
      return (
        resolution: resolution,
        finalizer: nil
      )
    }
  }

  public init<Behavior: StreamBehaviorType>(
    streamBehavior proposedBehavior: Behavior,
    handler: Behavior.Handler,
    tracker: BehaviorTracker
  ) where Behavior.Input == Input {
    let id = proposedBehavior.id
    let handler = handler
    self.id = id
    self.starter = { tracker, input, scope in
      var mutBehavior = proposedBehavior
      tracker
        .intercept(
          behavior: &mutBehavior,
          input: input
        )
      let finalBehavior = mutBehavior

      guard scope.canOwn()
      else {
        // If the scope itself can't own the behavior, return early without a finalizer.
        let resolution = Behaviors.Resolution(
          id: id,
          tracker: tracker,
          value: .init(id: id, state: .cancelled)
        )

        handler.cancel()
        return (resolution: resolution, finalizer: nil)
      }
      // For stream behaviors:
      // - we can not start immediately
      // - we return a finalizer that does so asynchronously.
      let resolution = Behaviors.Resolution(id: id, tracker: tracker)
      return (
        resolution: resolution,
        finalizer: {
          let task = Disposables.Task.detached {
            let behavior = await ActivatedBehavior(
              behavior: finalBehavior,
              input: input,
              handler: handler,
              resolution: resolution
            )
            scope.own(behavior)
            await resolution.markStarted()
            return await resolution.value
          } onDispose: {
            Task.detached {
              await resolution.resolve(to: .cancelled)
            }
          }
          scope.own(task)
          return await resolution.value
        }
      )
    }
  }

  // MARK: Public

  public typealias Starter = (
    resolution: Behaviors.Resolution,
    finalizer: (() async -> Behaviors.Resolved)?
  )

  public nonisolated func start(
    tracker: BehaviorTracker,
    input: Input,
    scope: some BehaviorScoping
  )
    -> Starter
  {
    starter(tracker, input, scope)
  }

  // MARK: Internal

  let id: BehaviorID

  // MARK: Private

  private let starter: (BehaviorTracker, Input, any BehaviorScoping)
    -> Starter

}
