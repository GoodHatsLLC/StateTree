import Disposable
import TreeActor
import Utilities

public struct StartableBehavior<Input> {

  // MARK: Lifecycle

  public init<Behavior: AsyncBehaviorType>(
    behavior proposedBehavior: Behavior,
    handler: Behavior.Handler
  ) where Behavior.Input == Input {
    let id = proposedBehavior.id
    let handler = handler
    self.id = id
    self.starter = { manager, input, scope in
      var mutBehavior = proposedBehavior
      manager
        .intercept(
          behavior: &mutBehavior,
          input: input
        )
      let finalBehavior = mutBehavior

      guard scope.canOwn()
      else {
        // If the scope itself can't own the behavior, return early without a finalizer.
        let resolution = Behaviors.Resolution(id: id, value: .init(id: id, state: .cancelled))
        manager.track(resolution: resolution)
        return (resolution: resolution, finalizer: nil)
      }
      // For an asynchronous behaviors:
      // - we can start it immediately
      // - we return a finalizer that does so asynchronously.
      let resolution = Behaviors.Resolution(id: id)
      manager.track(resolution: resolution)
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

  @TreeActor
  public init<Behavior: SyncBehaviorType>(
    behavior proposedBehavior: Behavior,
    handler: Behavior.Handler
  ) where Behavior.Input == Input {
    let id = proposedBehavior.id
    let handler = handler
    self.id = id
    self.starter = { manager, input, scope in
      var mutBehavior = proposedBehavior
      manager
        .intercept(
          behavior: &mutBehavior,
          input: input
        )
      let finalBehavior = mutBehavior

      guard scope.canOwn()
      else {
        handler.onCancel()
        // If the scope itself can't own the behavior, return early without a finalizer.
        let resolution = Behaviors.Resolution(id: id, value: .init(id: id, state: .cancelled))
        manager.track(resolution: resolution)
        return (resolution: resolution, finalizer: nil)
      }
      // For a synchronous behavior, we can start and resolve it
      // immediately and synchronously — and return a stub finalizer.
      var resolution = Behaviors.Resolution(id: id)
      let activated = ActivatedBehavior(
        behavior: finalBehavior,
        input: input,
        handler: handler,
        resolution: &resolution
      )
      manager.track(resolution: resolution)
      scope.own(activated)
      return (
        resolution: resolution,
        finalizer: { await resolution.value }
      )
    }
  }

  public init<Behavior: StreamBehaviorType>(
    behavior proposedBehavior: Behavior,
    handler: Behavior.Handler
  ) where Behavior.Input == Input {
    let id = proposedBehavior.id
    let handler = handler
    self.id = id
    self.starter = { manager, input, scope in
      var mutBehavior = proposedBehavior
      manager
        .intercept(
          behavior: &mutBehavior,
          input: input
        )
      let finalBehavior = mutBehavior

      guard scope.canOwn()
      else {
        // If the scope itself can't own the behavior, return early without a finalizer.
        let resolution = Behaviors.Resolution(id: id, value: .init(id: id, state: .cancelled))
        manager.track(resolution: resolution)
        return (resolution: resolution, finalizer: nil)
      }
      // For an asynchronous behaviors:
      // - we can start it immediately
      // - we return a finalizer that does so asynchronously.
      let resolution = Behaviors.Resolution(id: id)
      manager.track(resolution: resolution)
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

  public let id: BehaviorID

  public nonisolated func start(
    manager: BehaviorManager,
    input: Input,
    scope: some BehaviorScoping
  )
    -> Starter
  {
    starter(manager, input, scope)
  }

  // MARK: Private

  private let starter: (BehaviorManager, Input, any BehaviorScoping)
    -> Starter

}
