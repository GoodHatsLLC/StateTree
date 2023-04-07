@_spi(Implementation) import Behavior
import Disposable
import Emitter
import TreeActor
import Utilities

// MARK: - OnChange

public struct OnChange<B: Behavior>: Rules where B.Input: Equatable,
  B.Output: Sendable
{

  // MARK: Lifecycle

  public init<Input>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ value: Input,
    _ id: BehaviorID? = nil,
    action: @TreeActor @escaping (_ value: Input) -> Void
  ) where B == Behaviors.SyncSingle<Input, Void, Never> {
    self.value = value
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.SyncSingle<Input, Void, Never> = Behaviors
      .make(id, input: Input.self) { action($0) }
    self.callback = { scope, tracker, input in
      behavior.run(tracker: tracker, scope: scope, input: input)
    }
  }

  public init<Input>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ value: Input,
    _ id: BehaviorID? = nil,
    action: @TreeActor @escaping (_ value: Input) async -> Void
  ) where B == Behaviors.AsyncSingle<Input, Void, Never> {
    self.value = value
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.AsyncSingle<Input, Void, Never> = Behaviors
      .make(id, input: B.Input.self) { await action($0) }
    self.callback = { scope, tracker, input in
      behavior.run(tracker: tracker, scope: scope, input: input)
    }
  }

  public init<Input, Seq: AsyncSequence>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ value: Input,
    _ id: BehaviorID? = nil,
    run behaviorFunc: @escaping (_ value: Input) async -> Seq,
    onValue: @escaping @TreeActor (_ value: Seq.Element) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) where B == Behaviors.Stream<Input, Seq.Element, Error> {
    self.value = value
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "")
    let behavior: Behaviors.Stream<Input, Seq.Element, Error> = Behaviors
      .make(id, input: Input.self) {
        await behaviorFunc($0)
      }
    self.callback = { scope, tracker, value in
      behavior.run(
        tracker: tracker,
        scope: scope,
        input: value,
        handler: .init(onValue: onValue, onFinish: onFinish, onFailure: onFailure, onCancel: { })
      )
    }
  }

  @TreeActor
  public init(
    _ id: BehaviorID? = nil,
    _ value: B.Input,
    run behavior: B
  ) {
    var behavior = behavior
    self.value = value
    if let id = id {
      behavior.setID(to: id)
    }
    self.callback = { scope, tracker, value in
      behavior.run(tracker: tracker, scope: scope, input: value)
    }
  }

  @TreeActor
  public init(
    _ id: BehaviorID? = nil,
    _ value: B.Input,
    run behavior: B,
    handler: B.Handler
  )
    where B: Behavior
  {
    self.value = value
    var behavior = behavior
    if let id = id {
      behavior.setID(to: id)
    }
    self.callback = { scope, tracker, value in
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
    callback(scope, context.runtime.behaviorTracker, value)
  }

  public mutating func removeRule(with _: RuleContext) throws {
    scope.dispose()
  }

  public mutating func updateRule(
    from other: Self,
    with context: RuleContext
  ) throws {
    if other.value != value {
      scope.reset()
      value = other.value
      callback(scope, context.runtime.behaviorTracker, value)
    }
  }

  // MARK: Private

  private var value: B.Input
  private let callback: (any BehaviorScoping, BehaviorTracker, B.Input) -> Void
  private let scope: BehaviorStage = .init()
}
