import Disposable
import Foundation
import OrderedCollections
import TreeActor
@_spi(Implementation) import Utilities

// MARK: - RouteField

protocol RouteField<Router> {
  associatedtype Router: RouterType
  var type: RouteType { get }
  @TreeActor
  func connect(
    _ connection: RouteConnection,
    writeContext: RouterWriteContext
  )
  @TreeActor  var initialRecord: RouteRecord { get }
  var handle: any RouterHandle { get }
}

// MARK: - RouterHandle

@TreeActor
protocol RouterHandle {
  func apply() throws
}

// MARK: - Route

@propertyWrapper
public struct Route<Router: RouterType>: RouteField {

  // MARK: Lifecycle

  @TreeActor
  init(defaultRouter: Router) {
    self.inner = .init(
      defaultRouter: defaultRouter
    )
  }

  // MARK: Public

  @TreeActor  public var wrappedValue: Router.Value {
    inner.value
  }

  public var projectedValue: Route<Router> {
    self
  }

  // MARK: Internal

  @TreeActor  final class Inner: RouterHandle {

    // MARK: Lifecycle

    init(
      defaultRouter: Router
    ) {
      self.defaultRouter = defaultRouter
    }

    // MARK: Internal

    var appliedRouter: Router?

    var initialRecord: RouteRecord {
      activeRouter.initialRecord
    }

    var activeRouter: Router {
      appliedRouter ?? defaultRouter
    }

    var value: Router.Value {
      let router = activeRouter
      return (try? router.current) ?? router.fallback
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

    // MARK: Private

    private var connection: RouteConnection?
    private var writeContext: RouterWriteContext?
    private let defaultRouter: Router

  }

  var type: RouteType {
    Router.type
  }

  @TreeActor  var initialRecord: RouteRecord { inner.initialRecord }

  var handle: any RouterHandle { inner }

  @TreeActor
  func connect(
    _ connection: RouteConnection,
    writeContext: RouterWriteContext
  ) {
    inner.connect(
      connection,
      writeContext: writeContext
    )
  }

  @TreeActor
  func assign(router: Router) {
    assert(inner.appliedRouter == nil)
    inner.appliedRouter = router
  }

  @TreeActor
  func unassignRouter() {
    assert(inner.appliedRouter != nil)
    inner.appliedRouter = nil
  }

  // MARK: Private

  private let inner: Inner

}

// MARK: - UnconnectedNodeError

struct UnconnectedNodeError: Error { }
