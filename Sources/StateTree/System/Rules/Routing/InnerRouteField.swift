import Disposable
import OrderedCollections
import TreeActor

// MARK: - RouteHandle

@TreeActor
protocol RouteHandle: AnyObject {
  func apply() throws
  func makeDefaultRecord() -> RouteRecord
}

// MARK: - InnerRouteField

@TreeActor
final class InnerRouteField<Router: RouterType> {

  // MARK: Lifecycle

  nonisolated init(
    defaultRouter: Router
  ) {
    self.defaultRouter = defaultRouter
  }

  // MARK: Internal

  var appliedRouter: Router?

  // MARK: Private

  private var connection: RouteConnection?
  private var writeContext: RouterWriteContext?
  private let defaultRouter: Router

}

// MARK: RouteHandle

extension InnerRouteField: RouteHandle {

  var activeRouter: Router {
    appliedRouter ?? defaultRouter
  }

  var value: Router.Value {
    let router = activeRouter
    return (try? router.current) ?? router.fallback
  }

  func makeDefaultRecord() -> RouteRecord {
    do {
      return try defaultRouter.connectDefault()
    } catch {
      assertionFailure()
      return defaultRouter.fallbackRecord
    }
  }

  func connect(
    _ connection: RouteConnection,
    writeContext: RouterWriteContext
  ) {
    self.connection = connection
    self.writeContext = writeContext
  }

  func apply() throws {
    guard
      let connection,
      let writeContext
    else {
      throw UnconnectedNodeError()
    }
    try activeRouter.apply(
      connection: connection,
      writeContext: writeContext
    )
  }

}

// MARK: - UnconnectedNodeError

struct UnconnectedNodeError: Error { }
