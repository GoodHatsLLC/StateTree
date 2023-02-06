import Disposable
import Emitter

// MARK: - OnReceive

/// TODO: replace with behavior oriented lifecycle handlers
@TreeActor
public struct OnReceive<Value>: Rules {

  // MARK: Lifecycle

  public init(
    _ emitter: some Emitter<Value>,
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinished: @escaping @TreeActor () -> Void = { },
    onError: @escaping @TreeActor (Error) -> Void = { _ in }
  ) {
    self.emitter = emitter.erase()
    self.onFinished = onFinished
    self.onError = onError
    self.onValue = onValue
  }

  // MARK: Public

  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    switch lifecycle {
    case .didStart:
      emitter
        .subscribe { [onValue] value in
          onValue(value)
        } finished: { [onFinished] in
          onFinished()
        } failed: { [onError] error in
          onError(error)
        }
        .stage(on: stage)
    case .didUpdate:
      break
    case .willStop:
      stage.dispose()
    case .handleIntent:
      break
    }
    return .init()
  }

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from _: OnReceive<Value>,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  private let stage = DisposableStage()
  private let emitter: AnyEmitter<Value>
  private let onFinished: @TreeActor () -> Void
  private let onError: @TreeActor (Error) -> Void
  private let onValue: @TreeActor (Value) -> Void

}

extension Rules {
  public func onReceive<Value>(
    _ emitter: some Emitter<Value>,
    onValue: @escaping @TreeActor (Value) -> Void,
    onFinished: @escaping @TreeActor () -> Void = { },
    onError: @escaping @TreeActor (Error) -> Void = { _ in }
  )
    -> some Rules
  {
    OnReceive(
      emitter,
      onValue: onValue,
      onFinished: onFinished,
      onError: onError
    )
  }
}
