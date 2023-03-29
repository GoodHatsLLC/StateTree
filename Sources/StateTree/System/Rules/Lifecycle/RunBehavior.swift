@_spi(Implementation) import Behaviors
import Disposable
import Emitter
import Utilities

// MARK: - RunBehavior

public struct RunBehavior: Rules {

  // MARK: Lifecycle

  public init<Output>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Make<Void, Output>.Func.NonThrowing,
    onSuccess: @escaping @TreeActor (_ value: Output) -> Void
  ) {
    let behavior = Behaviors.make(
      id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "rule"),
      subscribe: subscribe
    )
    self.startable = StartableBehavior(
      behavior: behavior,
      handler: .init(onSuccess: onSuccess, onCancel: { })
    )
  }

  public init<Output>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    subscribe: @escaping Behaviors.Make<Void, Output>.Func.Throwing,
    onResult: @escaping @TreeActor (Result<Output, any Error>) -> Void
  ) {
    let behavior = Behaviors.make(
      id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "rule"),
      subscribe: subscribe
    )
    self.startable = StartableBehavior(
      behavior: behavior,
      handler: .init(onResult: onResult, onCancel: { })
    )
  }

  public init<Seq: AsyncSequence>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    behavior: @escaping () async -> Seq,
    onValue: @escaping @TreeActor (_ value: Seq.Element) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (_ error: Error) -> Void
  ) {
    let behavior = Behaviors.make(
      id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "rule"),
      subscribe: behavior
    )
    self.startable = StartableBehavior(
      behavior: behavior,
      handler: .init(onValue: onValue, onFinish: onFinish, onFailure: onFailure, onCancel: { })
    )
  }

  public init<Value>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    behavior: @escaping () async -> some Emitting<Value>,
    onValue: @escaping @TreeActor (_ value: Value) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (_ error: Error) -> Void
  ) {
    self.init(
      moduleFile,
      line,
      column,
      id: id,
      behavior: { await behavior().values },
      onValue: onValue,
      onFinish: onFinish,
      onFailure: onFailure
    )
  }

  // MARK: Public

  public func act(
    for lifecycle: RuleLifecycle,
    with context: RuleContext
  )
    -> LifecycleResult
  {
    switch lifecycle {
    case .didStart:
      let (_, finalizer) = startable.start(
        manager: context.runtime.behaviorManager,
        input: (),
        scope: context.scope
      )
      if let finalizer {
        let disposable = Disposables.Task.detached {
          await finalizer()
        } onDispose: { }
        context.scope.own(disposable)
      }
    case .didUpdate:
      break
    case .willStop:
      break
    case .handleIntent:
      break
    }
    return .init()
  }

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from _: RunBehavior,
    with _: RuleContext
  ) throws { }

  // MARK: Internal

  let startable: StartableBehavior<Void>

}

#if canImport(Combine)
import Combine
extension RunBehavior {
  /// Make an unbounded async-safe publisher -> async -> Behavior bridge.
  ///
  /// This initializer creates an intermediate subscription on a single actor before re-emitting
  /// its values for concurrent consumption.
  /// Publishers like `PassthroughSubject` and `CurrentValueSubject` whose
  /// emissions are not all sent from the same actor will drop values when bridged with `.values`.
  public init<Element>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    behavior: @escaping () async -> some Publisher<Element, any Error>,
    onValue: @escaping @TreeActor (_ value: Element) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (_ error: any Error) -> Void
  ) {
    self.init(
      moduleFile,
      line,
      column,
      id: id,
      behavior: {
        let publisher = await behavior()
        return Async.Combine.bridge(publisher: publisher)
      },
      onValue: onValue,
      onFinish: onFinish,
      onFailure: onFailure
    )
  }

  /// Make an unbounded async-safe publisher -> async -> Behavior bridge.
  ///
  /// This initializer creates an intermediate subscription on a single actor before re-emitting
  /// its values for concurrent consumption.
  /// Publishers like `PassthroughSubject` and `CurrentValueSubject` whose
  /// emissions are not all sent from the same actor will drop values when bridged with `.values`.
  public init<Element>(
    _ moduleFile: String = #file,
    _ line: Int = #line,
    _ column: Int = #column,
    id: BehaviorID? = nil,
    behavior: @escaping () async -> some Publisher<Element, Never>,
    onValue: @escaping @TreeActor (_ value: Element) -> Void,
    onFinish: @escaping @TreeActor () -> Void,
    onFailure: @escaping @TreeActor (_ error: any Error) -> Void
  ) {
    self.init(
      moduleFile,
      line,
      column,
      id: id,
      behavior: {
        let publisher = await behavior()
        return Async.Combine.bridge(publisher: publisher.setFailureType(to: Error.self))
      },
      onValue: onValue,
      onFinish: onFinish,
      onFailure: onFailure
    )
  }
}
#endif
