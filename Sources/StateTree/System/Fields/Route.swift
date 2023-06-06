import Disposable
import OrderedCollections
import TreeActor

// MARK: - RouteFieldType

public protocol RouteFieldType<Router> {
  associatedtype Router: RouterType
  @_spi(Implementation) @TreeActor var fieldID: FieldID? { get }
}

// MARK: - RouteFieldInternal

protocol RouteFieldInternal<Router>: RouteFieldType {
  var handle: any RouteHandle { get }
}

// MARK: - Route

@propertyWrapper
public struct Route<Router: RouterType>: RouteFieldInternal {

  // MARK: Lifecycle

  init(defaultRouter: Router) {
    self.inner = .init(
      defaultRouter: defaultRouter
    )
  }

  public var projectedValue: Route<Router> {
    self
  }

  // MARK: Public

  @TreeActor public var wrappedValue: Router.Value {
    inner.value
  }

  @_spi(Implementation) @TreeActor public var fieldID: FieldID? {
    inner.fieldID
  }

  // MARK: Internal

  let inner: InnerRouteField<Router>

  var handle: any RouteHandle {
    inner
  }
}
