import Disposable

// MARK: - Attach
@TreeActor
public struct Attach<Router: RouterType>: Rules {

  // MARK: Lifecycle

  public init(
    router: Router,
    to route: Route<Router>
  ) {
    self.route = route
    self.router = router
  }

  // MARK: Public

  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    switch lifecycle {
    case .didStart:
      break
    case .didUpdate:
      break
    case .willStop:
      break
    case .handleIntent:
      break
    }
    return .init()
  }

  public mutating func applyRule(with context: RuleContext) throws {
    try router.applyRule(with: context)
  }

  public mutating func removeRule(with context: RuleContext) throws {
    try router.removeRule(with: context)
  }

  public mutating func updateRule(
    from new: Self,
    with context: RuleContext
  ) throws {
    let new = new.router
    try router.updateRule(from: new, with: context)
  }

  // MARK: Internal

  var router: Router
  let route: Route<Router>

}
