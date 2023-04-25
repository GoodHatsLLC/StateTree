import Emitter
import TreeActor

// MARK: - AttachableBehavior

public struct AttachableBehavior<B: Behavior> {

  // MARK: Lifecycle

  @TreeActor
  public init(
    behavior: B,
    tracker: BehaviorTracker
  ) {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        behavior: behavior,
        handler: handler,
        tracker: tracker
      )
    }
  }

  @TreeActor
  public init(
    behavior: B,
    tracker: BehaviorTracker
  ) where B: SyncBehaviorType {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        syncBehavior: behavior,
        handler: handler,
        tracker: tracker
      )
    }
  }

  public init(
    behavior: B,
    tracker: BehaviorTracker
  ) where B: AsyncBehaviorType {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        asyncBehavior: behavior,
        handler: handler,
        tracker: tracker
      )
    }
  }

  public init(
    behavior: B,
    tracker: BehaviorTracker
  ) where B: StreamBehaviorType {
    self.id = behavior.id
    self.attacher = { handler in
      StartableBehavior(
        streamBehavior: behavior,
        handler: handler,
        tracker: tracker
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
