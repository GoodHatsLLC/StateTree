import Disposable

public struct StartableBehavior<Input> {

  // MARK: Lifecycle

  init<Behavior: BehaviorType>(
    behavior: Behavior,
    handler: Behavior.Handler
  ) where Behavior.Input == Input {
    let id = behavior.id
    let handler = handler
    self.id = id
    self.starter = { manager, input, resolution in
      ActivatedBehavior(
        behavior: behavior,
        input: input,
        manager: manager,
        handler: handler,
        resolution: resolution
      )
    }
  }

  // MARK: Public

  public let id: BehaviorID

  // MARK: Internal

  @TreeActor
  func start(
    manager: BehaviorManager,
    input: Input,
    resolution: Behaviors.Resolution? = nil
  )
    -> ActivatedBehavior
  {
    starter(manager, input, resolution)
  }

  // MARK: Private

  private let starter: @TreeActor (BehaviorManager, Input, Behaviors.Resolution?)
    -> ActivatedBehavior

}
