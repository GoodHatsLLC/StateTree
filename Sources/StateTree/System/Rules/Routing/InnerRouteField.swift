import Disposable
import OrderedCollections
import TreeActor

// MARK: - RouteHandle

@TreeActor
protocol RouteHandle: AnyObject {
  func apply() throws
  var defaultRecord: RouteRecord { get }
}

// MARK: - InnerRouteField

@TreeActor
final class InnerRouteField<Router: RouterType> {

  // MARK: Lifecycle

  nonisolated init(
    defaultRouter: Router
  ) {
    self.defaultRouter = defaultRouter
    self.activeDefault = defaultRouter
  }

  // MARK: Internal

  var appliedRouter: Router? {
    willSet {
      // if setting or unsetting the router override
      // the stored state of the default router should
      // be removed so that it can re-apply.
      switch (appliedRouter, newValue) {
      case (.none, .some):
        activeDefault = defaultRouter
      case (.some, .none):
        activeDefault = defaultRouter
      default:
        break
      }
    }
  }

  // MARK: Private

  private var connection: RouteConnection?
  private var writeContext: RouterWriteContext?
  private var activeDefault: Router
  private let defaultRouter: Router

}

// MARK: RouteHandle

extension InnerRouteField: RouteHandle {

  var activeRouter: Router {
    get {
      appliedRouter ?? activeDefault
    }
    set {
      // work out the underlying router
      // and update only it
      if appliedRouter != nil {
        appliedRouter = newValue
      } else {
        activeDefault = newValue
      }
    }
  }

  var value: Router.Value {
    let router = activeRouter
    return (try? router.current) ?? router.fallback
  }

  var defaultRecord: RouteRecord {
    defaultRouter.defaultRecord
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
