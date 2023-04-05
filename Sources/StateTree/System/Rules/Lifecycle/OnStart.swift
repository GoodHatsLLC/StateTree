@_spi(Implementation) import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnStart

public struct OnStart<B: Behavior>: Rules where B.Input == Void,
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
    self.callback = { scope, tracker in
      behavior.run(tracker: tracker, scope: scope, input: ())
    }
  }

  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    id: BehaviorID? = nil,
    _ action: @TreeActor @escaping () async -> Void
  ) where B == Behaviors.AsyncSingle<Void, Void, Never> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.AsyncSingle<Void, Void, Never> = Behaviors
      .make(id, input: Void.self) { await action() }
    self.callback = { scope, tracker in
      behavior.run(tracker: tracker, scope: scope, input: ())
    }
  }

  public init<Seq: AsyncSequence>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    id: BehaviorID? = nil,
    _ behaviorFunc: @escaping () async -> Seq,
    onValue: @escaping @TreeActor (_ value: Seq.Element) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) where B == Behaviors.Stream<Void, Seq.Element, Error> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.Stream<Void, Seq.Element, Error> = Behaviors
      .make(id, input: Void.self) {
        await behaviorFunc()
      }
    self.callback = { scope, tracker in
      behavior.run(
        tracker: tracker,
        scope: scope,
        input: (),
        handler: .init(onValue: onValue, onFinish: onFinish, onFailure: onFailure, onCancel: { })
      )
    }
  }

  @TreeActor
  public init(
    _: B.Input,
    id: BehaviorID? = nil,
    run behavior: B
  ) {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    self.callback = { scope, tracker in
      behavior.run(tracker: tracker, scope: scope, input: ())
    }
  }

  @TreeActor
  public init(
    _ value: B.Input,
    id: BehaviorID? = nil,
    run behavior: B,
    handler: B.Handler
  ) {
    var behavior = behavior
    if let id {
      behavior.setID(to: id)
    }
    self.callback = { scope, tracker in
      behavior.run(tracker: tracker, scope: scope, input: value, handler: handler)
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
    callback(scope, context.runtime.behaviorTracker)
  }

  public mutating func removeRule(with _: RuleContext) throws {
    scope.dispose()
  }

  public mutating func updateRule(
    from _: Self,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  private let callback: (any BehaviorScoping, BehaviorTracker) -> Void
  private let scope: BehaviorStage = .init()
}
