// MARK: - OnChange

@TreeActor
public struct OnChange<Value: Equatable>: Rules {

  // MARK: Lifecycle

  public init(
    _ value: Value,
    _ action: @TreeActor @escaping (_ value: Value) -> Void
  ) {
    self.value = value
    self.lastValue = value
    self.action = action
  }

  // MARK: Public

  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    switch lifecycle {
    case .didStart:
      action(value)
    case .didUpdate:
      if value != lastValue {
        action(value)
      }
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
    from new: Self,
    with _: RuleContext
  ) throws {
    lastValue = value
    value = new.value
  }

  // MARK: Private

  private var lastValue: Value
  private var value: Value
  private var action: @TreeActor (_ value: Value) -> Void

}
