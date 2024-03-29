import Disposable
import TreeActor

// MARK: - Serve

public struct Serve<Router: RouterType>: Rules {

  // MARK: Lifecycle

  init(
    router: Router,
    at route: Route<Router>
  ) {
    self.route = route
    self.router = router
  }

  // MARK: Public

  public func act(for _: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    .init()
  }

  public mutating func applyRule(with context: RuleContext) throws {
    var router = router
    router.assign(
      .init(
        depth: context.depth,
        dependencies: context.dependencies
      )
    )
    route.inner.appliedRouter = router
  }

  public mutating func removeRule(with _: RuleContext) throws {
    route.inner.appliedRouter = nil
  }

  public mutating func updateRule(
    from new: Self,
    with context: RuleContext
  ) throws {
    assert(route.inner.appliedRouter != nil)
    var newRouter = new.router
    newRouter.assign(
      .init(
        depth: context.depth,
        dependencies: context.dependencies
      )
    )
    router = newRouter
    route.inner.appliedRouter?.update(from: newRouter)
  }

  public mutating func syncToState(with context: RuleContext) throws {
    var router = router
    router.assign(
      .init(
        depth: context.depth,
        dependencies: context.dependencies
      )
    )
    route.inner.appliedRouter = router
  }

  // MARK: Internal

  var router: Router
  let route: Route<Router>

}
