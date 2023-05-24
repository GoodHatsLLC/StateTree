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
    .init()
  }

  public mutating func applyRule(with _: RuleContext) throws {
    route.inner.appliedRouter = router
  }

  public mutating func removeRule(with _: RuleContext) throws {
    route.inner.appliedRouter = nil
  }

  public mutating func updateRule(
    from new: Self,
    with _: RuleContext
  ) throws {
    assert(route.inner.appliedRouter != nil)
    router = new.router
    route.inner.appliedRouter?.update(from: new.router)
  }

  // MARK: Internal

  var router: Router
  let route: Route<Router>

}
