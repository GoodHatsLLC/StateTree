// MARK: - OnStart

@TreeActor
public struct OnStart: Rules {

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
      action()
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
    from _: OnStart,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  private var action: () -> Void

}

extension Rules {
  public func onStart(action: @escaping () -> Void) -> some Rules {
    OnStart(action: action)
  }
}
