import Emitter
import TreeActor

// MARK: - AttachableBehavior

public struct AttachableBehavior<B: Behavior> {

  // MARK: Lifecycle

  @TreeActor
  public init(
    behavior: B
  ) {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        behavior: behavior,
        handler: handler
      )
    }
  }

  @TreeActor
  public init(
    behavior: B
  ) where B: SyncBehaviorType {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        behavior: behavior,
        handler: handler
      )
    }
  }

  public init(
    behavior: B
  ) where B: AsyncBehaviorType {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        behavior: behavior,
        handler: handler
      )
    }
  }

  public init(
    behavior: B
  ) where B: StreamBehaviorType {
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

  private let attacher: (B.Handler) -> StartableBehavior<B.Input>
}

extension AttachableBehavior {
  func attach(
    handler: B.Handler
  ) -> StartableBehavior<B.Input> {
    attacher(handler)
  }
}
