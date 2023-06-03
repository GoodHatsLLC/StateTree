import Disposable
import OrderedCollections
import TreeActor

// MARK: - RouteField

protocol RouteField<Router> {
  associatedtype Router: RouterType
  var handle: any RouteHandle { get }
}

// MARK: - Route

@propertyWrapper
public struct Route<Router: RouterType>: RouteField {

  // MARK: Lifecycle

  init(defaultRouter: Router) {
    self.inner = .init(
      defaultRouter: defaultRouter
    )
  }

  // MARK: Public

  @TreeActor public var wrappedValue: Router.Value {
    inner.value
  }

  public var projectedValue: Route<Router> {
    self
  }

  // MARK: Internal

  let inner: InnerRouteField<Router>

  var handle: any RouteHandle {
    inner
  }
}
