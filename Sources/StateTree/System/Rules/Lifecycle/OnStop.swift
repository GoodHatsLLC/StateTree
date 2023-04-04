@_spi(Implementation) import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnStop

public struct OnStop<B: Behavior>: Rules where B.Input == Void,
  B.Output: Sendable
{

  // MARK: Lifecycle

  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    id: BehaviorID? = nil,
    _ action: @TreeActor @escaping () -> Void
  ) where B == Behaviors.SyncSingle<Void, Void, Never> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.SyncSingle<Void, Void, Never> = Behaviors
      .make(id, input: Void.self) { action() }
    self.callback = { scope, manager in
      behavior.run(manager: manager, scope: scope, input: ())
    }
  }

  @TreeActor
  public init(
    id: BehaviorID? = nil,
    run behavior: B
  ) where B.Handler == Behaviors.SingleHandler<
    Synchronous,
    B.Output,
    B.Failure
  > {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    self.callback = { scope, manager in
      behavior.run(manager: manager, scope: scope, input: ())
    }
  }

  @TreeActor
  public init(
    id: BehaviorID? = nil,
    run behavior: B,
    handler: B.Handler
  )
    where B.Handler.SubscribeType == Synchronous
  {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    self.callback = { scope, manager in
      behavior.run(manager: manager, scope: scope, input: (), handler: handler)
    }
  }

  // MARK: Public

  public func act(
    for _: RuleLifecycle,
    with _: RuleContext
  )
    -> LifecycleResult
  {
    .init()
  }

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with context: RuleContext) throws {
    callback(scope, context.runtime.behaviorManager)
    scope.dispose()
  }

  public mutating func updateRule(
    from _: Self,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  private let callback: (any BehaviorScoping, BehaviorManager) -> Void
  private let scope: BehaviorStage = .init()
}
