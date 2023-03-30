import Disposable
import TreeActor
import Utilities

// MARK: - ScopedBehavior

public struct ScopedBehavior<Behavior: BehaviorType>: HandlerSurface {

  // MARK: Lifecycle

  public init(
    behavior: Behavior,
    scope: any BehaviorScoping,
    manager: BehaviorManager,
    input: Behavior.Input
  ) where Behavior: AsyncBehaviorType {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager,
      input: input
    )
  }

  @TreeActor
  public init(
    behavior: Behavior,
    scope: any BehaviorScoping,
    manager: BehaviorManager,
    input: Behavior.Input
  ) where Behavior: SyncBehaviorType {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager,
      input: input
    )
  }

  public init(
    behavior: Behavior,
    scope: any BehaviorScoping,
    manager: BehaviorManager,
    input: Behavior.Input
  ) where Behavior: StreamBehaviorType {
    self.init(
      behavior: AttachableBehavior(behavior: behavior),
      scope: scope,
      manager: manager,
      input: input
    )
  }

  fileprivate init(
    behavior: AttachableBehavior<Behavior>,
    scope: any BehaviorScoping,
    manager: BehaviorManager,
    input: Behavior.Input
  ) {
    self.id = behavior.id
    self.behavior = behavior
    self.scope = scope
    self.manager = manager
    self.input = input
  }

  // MARK: Public

  public var surface: Surface<Behavior> {
    .init(input: input, behavior: behavior, scope: scope, manager: manager)
  }

  // MARK: Internal

  let id: BehaviorID

  // MARK: Private

  private let input: Behavior.Input
  private let behavior: AttachableBehavior<Behavior>
  private let scope: any BehaviorScoping
  private let manager: BehaviorManager

}
