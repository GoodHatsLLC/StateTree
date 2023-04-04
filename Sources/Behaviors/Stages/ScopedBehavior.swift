import Disposable
import TreeActor
import Utilities

// MARK: - ScopedBehavior

public struct ScopedBehavior<B: Behavior>: HandlerSurface {

  // MARK: Lifecycle

  public init(
    behavior: B,
    scope: any BehaviorScoping,
    manager: BehaviorManager,
    input: B.Input
  ) where B: AsyncBehaviorType {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager,
      input: input
    )
  }

  @TreeActor
  public init(
    behavior: B,
    scope: any BehaviorScoping,
    manager: BehaviorManager,
    input: B.Input
  ) where B: SyncBehaviorType {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager,
      input: input
    )
  }

  public init(
    behavior: B,
    scope: any BehaviorScoping,
    manager: BehaviorManager,
    input: B.Input
  ) where B: StreamBehaviorType {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager,
      input: input
    )
  }

  fileprivate init(
    behavior: AttachableBehavior<B>,
    scope: any BehaviorScoping,
    manager: BehaviorManager,
    input: B.Input
  ) {
    self.id = behavior.id
    self.behavior = behavior
    self.scope = scope
    self.manager = manager
    self.input = input
  }

  // MARK: Public

  public var surface: Surface<B> {
    .init(input: input, behavior: behavior, scope: scope, manager: manager)
  }

  // MARK: Internal

  let id: BehaviorID

  // MARK: Private

  private let input: B.Input
  private let behavior: AttachableBehavior<B>
  private let scope: any BehaviorScoping
  private let manager: BehaviorManager

}
