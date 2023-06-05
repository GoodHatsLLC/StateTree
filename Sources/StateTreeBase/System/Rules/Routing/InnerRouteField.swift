import Disposable
import OrderedCollections
import TreeActor

// MARK: - RouteHandle

@TreeActor
protocol RouteHandle: AnyObject {
  func reset()
  func apply() throws
  func syncToState() throws -> [AnyScope]
  func setField(id: FieldID, in runtime: Runtime, rules: RouterRuleContext)
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
  }

  // MARK: Internal

  private(set) var fieldID: FieldID?

  var appliedRouter: Router? {
    willSet {
      // if setting or unsetting the router override
      // the stored state of the default router should
      // be removed so that it can re-apply.
      switch (appliedRouter, newValue) {
      case (.none, .some):
        activeDefault = defaultWithContext()
      case (.some, .none):
        activeDefault = defaultWithContext()
      default:
        break
      }
    }
  }

  // MARK: Private

  private var runtime: Runtime?
  private var rules: RouterRuleContext?
  private var activeDefault: Router?
  private let defaultRouter: Router

}

// MARK: RouteHandle

extension InnerRouteField: RouteHandle {

  // MARK: Internal

  var activeRouter: Router {
    get {
      appliedRouter ?? activeDefault ?? {
        assertionFailure()
        return defaultRouter
      }()
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
    guard
      let fieldID,
      let runtime,
      let value = try? activeRouter.current(at: fieldID, in: runtime)
    else {
      assertionFailure()
      return activeRouter.fallback
    }
    return value
  }

  var defaultRecord: RouteRecord {
    defaultRouter.defaultRecord
  }

  func reset() {
    appliedRouter = nil
  }

  func setField(id: FieldID, in runtime: Runtime, rules: RouterRuleContext) {
    assert(self.runtime == nil)
    assert(self.rules == nil)
    fieldID = id
    self.runtime = runtime
    self.rules = rules
    activeDefault = defaultWithContext()
  }

  func apply() throws {
    guard
      let fieldID,
      let runtime
    else {
      throw UnknownRouteFieldError()
    }
    try activeRouter.apply(at: fieldID, in: runtime)
  }

  func syncToState() throws -> [AnyScope] {
    guard
      let fieldID,
      let runtime
    else {
      throw UnknownRouteFieldError()
    }
    return try activeRouter.syncToState(field: fieldID, in: runtime)
  }

  // MARK: Private

  private func defaultWithContext() -> Router {
    if let rules {
      var defaultRouter = defaultRouter
      defaultRouter.assign(rules)
      return defaultRouter
    } else {
      assertionFailure()
      return defaultRouter
    }
  }

}

// MARK: - UnknownRouteFieldError

struct UnknownRouteFieldError: Error { }
