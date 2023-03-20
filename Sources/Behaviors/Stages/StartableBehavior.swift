import Disposable
import TreeActor
import Utilities

public struct StartableBehavior<Input> {

  // MARK: Lifecycle

  public init<Behavior: BehaviorType>(
    behavior: Behavior,
    handler: Behavior.Handler
  ) where Behavior.Input == Input {
    let id = behavior.id
    let handler = handler
    self.id = id
    self.resolution = Behaviors.Resolution(id: id)
    self.starter = { manager, input, resolution, scope in
      var behavior = behavior
      manager
        .intercept(
          behavior: &behavior,
          input: input
        )
      manager.track(resolution: resolution)
      return { [behavior] in
        let task = Disposables.Task.detached {
          let behavior = await ActivatedBehavior(
            behavior: behavior,
            input: input,
            handler: handler,
            resolution: resolution,
            scope: scope
          )
          await resolution.markStarted()
          return await behavior.resolution.value
        } onDispose: {
          Task.detached {
            await resolution.resolve(to: .cancelled)
          }
        }
        scope.own(task)
        return task
      }
    }
  }

  // MARK: Public

  public let id: BehaviorID
  public let resolution: Behaviors.Resolution

  public func start(
    manager: BehaviorManager,
    input: Input,
    scope: some BehaviorScoping
  ) -> () async -> Disposables.Task<Behaviors.Resolved, Never> {
    starter(manager, input, resolution, scope)
  }

  // MARK: Private

  private let starter: (BehaviorManager, Input, Behaviors.Resolution, any BehaviorScoping)
    -> () async -> Disposables.Task<Behaviors.Resolved, Never>

}
