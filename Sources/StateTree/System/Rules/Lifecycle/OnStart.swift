@_spi(Implementation) import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnStart

public struct OnStart<Behavior: BehaviorType>: Rules where Behavior.Input == Void {

  // MARK: Lifecycle

  @TreeActor
  public init(
    _ action: @TreeActor @escaping () -> Void
  ) where Behavior == Behaviors.SyncSingle<Void, Void, Never> {
    let behavior: Behaviors.SyncSingle<Behavior.Input, Void, Never> = Behaviors
      .make(input: Behavior.Input.self) { action() }
    self.start = { scope, manager in
      behavior.run(manager: manager, scope: scope, input: ())
    }
  }

  public init(
    _ action: @TreeActor @escaping () async -> Void
  ) where Behavior == Behaviors.AsyncSingle<Void, Void, Never> {
    let behavior: Behaviors.AsyncSingle<Behavior.Input, Void, Never> = Behaviors
      .make(input: Behavior.Input.self) { await action() }
    self.start = { scope, manager in
      behavior.run(manager: manager, scope: scope, input: ())
    }
  }

  public init<Seq: AsyncSequence>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    behavior behaviorFunc: @escaping () async -> Seq,
    onValue: @escaping @TreeActor (_ value: Seq.Element) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (_ error: Error) -> Void
  ) where Behavior == Behaviors.Stream<Void, Seq.Element, Error> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.Stream<Void, Seq.Element, Error> = Behaviors
      .make(id, input: Void.self) { _ in
        await behaviorFunc()
      }
    self.start = { scope, manager in
      behavior.run(
        manager: manager,
        scope: scope,
        input: (),
        handler: .init(onValue: onValue, onFinish: onFinish, onFailure: onFailure, onCancel: { })
      )
    }
  }

  @TreeActor
  public init(
    run behavior: Behavior
  )
    where Behavior: BehaviorEffect
  {
    self.start = { scope, manager in
      behavior.run(manager: manager, scope: scope, input: ())
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

  public mutating func applyRule(with context: RuleContext) throws {
    start(scope, context.runtime.behaviorManager)
  }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from _: Self,
    with _: RuleContext
  ) throws { }

  // MARK: Internal

  let start: (any BehaviorScoping, BehaviorManager) -> Void
  let scope: BehaviorStage = .init()
}
