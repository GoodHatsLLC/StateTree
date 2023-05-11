import TreeActor
@_spi(Implementation) import Behavior

// MARK: - OnReceive

public struct OnReceive<Value: Sendable>: Rules {

  // MARK: Lifecycle

  public init<Seq: AsyncSequence>(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ seq: Seq,
    _ id: BehaviorID? = nil,
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) where Seq.Element == Value {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: ""
    )
    let behavior: Behaviors.Stream<Void, Seq.Element, Error> = Behaviors
      .make(id, input: Void.self) {
        seq
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

  // MARK: Public

  public func act(for _: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
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

#if canImport(Emitter)
import Emitter
extension OnReceive {

  @_spi(Implementation)
  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ emitter: some Emitter<Value, Error>,
    _ id: BehaviorID? = nil,
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: ""
    )
    let behavior: Behaviors.Stream<Void, Value, Error> = Behaviors.make(id, input: Void.self) {
      emitter
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
}
#endif

#if canImport(Combine)
import Combine
extension OnReceive {
  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ publisher: some Publisher<Value, some Error>,
    _ id: BehaviorID? = nil,
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void = { },
    onFailure: @escaping @TreeActor (_ error: Error) -> Void = { _ in }
  ) {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: ""
    )
    let behavior: Behaviors.Stream<Void, Value, Error> = Behaviors.make(id, input: Void.self) {
      publisher
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
}
#endif
