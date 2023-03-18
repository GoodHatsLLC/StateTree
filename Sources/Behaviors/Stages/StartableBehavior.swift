import Disposable
import TreeActor

public struct StartableBehavior<Input> {

  // MARK: Lifecycle

  init<Behavior: BehaviorType>(
    behavior: Behavior,
    handler: Behavior.Handler
  ) where Behavior.Input == Input {
    let id = behavior.id
    let handler = handler
    self.id = id
    self.resolution = Behaviors.Resolution(id: id)
    self.starter = { manager, input, resolution, scope in
      await ActivatedBehavior(
        behavior: behavior,
        input: input,
        manager: manager,
        handler: handler,
        resolution: resolution,
        scope: scope
      )
    }
  }

  // MARK: Public

  public let id: BehaviorID
  public let resolution: Behaviors.Resolution

  // MARK: Internal

  func start(
    manager: BehaviorManager,
    input: Input,
    scope: some BehaviorScoping
  ) async
    -> ActivatedBehavior
  {
    await starter(manager, input, resolution, scope)
  }

  // MARK: Private

  private let starter: (BehaviorManager, Input, Behaviors.Resolution, any BehaviorScoping) async
    -> ActivatedBehavior

}
