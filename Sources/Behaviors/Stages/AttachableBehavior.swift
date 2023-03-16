import Emitter

// MARK: - AttachableBehavior

public struct AttachableBehavior<Behavior: BehaviorType> {

  // MARK: Lifecycle

  init(
    behavior: Behavior
  ) {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        behavior: behavior,
        handler: handler
      )
    }
  }

  // MARK: Public

  public let id: BehaviorID

  func attach(
    handler: Behavior.Handler
  ) -> StartableBehavior<Behavior.Input> {
    attacher(handler)
  }

  // MARK: Private
  private let attacher: (Behavior.Handler) -> StartableBehavior<Behavior.Input>
}
