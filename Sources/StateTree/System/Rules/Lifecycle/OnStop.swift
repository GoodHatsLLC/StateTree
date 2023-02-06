// MARK: - OnStop

@TreeActor
public struct OnStop: Rules {

  // MARK: Lifecycle

  public init(
    action: @escaping () -> Void
  ) {
    self.action = action
  }

  // MARK: Public

  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    switch lifecycle {
    case .didStart:
      break
    case .didUpdate:
      break
    case .willStop:
      action()
    case .handleIntent:
      break
    }
    return .init()
  }

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from _: OnStop,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  private var action: () -> Void

}

extension Rules {
  public func onStop(action: @escaping () -> Void) -> OnStop {
    OnStop(action: action)
  }
}
