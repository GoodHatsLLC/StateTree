import Emitter
import TreeActor

// MARK: - AttachableBehavior

public struct AttachableBehavior<Behavior: BehaviorType> {

  // MARK: Lifecycle

  @TreeActor
  public init(
    behavior: Behavior
  ) where Behavior: SyncBehaviorType {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        behavior: behavior,
        handler: handler
      )
    }
  }

  public init(
    behavior: Behavior
  ) where Behavior: AsyncBehaviorType {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        behavior: behavior,
        handler: handler
      )
    }
  }

  public init(
    behavior: Behavior
  ) where Behavior: StreamBehaviorType {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        behavior: behavior,
        handler: handler
      )
    }
  }

  // MARK: Internal

  let id: BehaviorID

  // MARK: Private

  private let attacher: (Behavior.Handler) -> StartableBehavior<Behavior.Input>
}

extension AttachableBehavior {
  func attach(
    handler: Behavior.Handler
  ) -> StartableBehavior<Behavior.Input> {
    attacher(handler)
  }
}
