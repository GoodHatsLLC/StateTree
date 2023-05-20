import Disposable
import TreeActor

// MARK: - Attach
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

  public func act(for _: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    return .init()
  }

  public mutating func applyRule(with _: RuleContext) throws {
    route.assign(router: router)
  }

  public mutating func removeRule(with _: RuleContext) throws {
    route.unassignRouter()
  }

  public mutating func updateRule(
    from new: Self,
    with _: RuleContext
  ) throws {
    router = new.router
    route.unassignRouter()
    route.assign(router: router)
  }

  // MARK: Internal

  var router: Router
  let route: Route<Router>

}
