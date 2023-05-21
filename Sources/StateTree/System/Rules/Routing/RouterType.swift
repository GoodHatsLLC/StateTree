import OrderedCollections
import TreeActor

// MARK: - RouteConnection

public struct RouteConnection {
  let runtime: Runtime
  let fieldID: FieldID
}

// MARK: - RouterWriteContext

public struct RouterWriteContext {
  let depth: Int
  let dependencies: DependencyValues
}

// MARK: - RouterType

public protocol RouterType<Value> {
  associatedtype Value
  static var type: RouteType { get }
  var fallback: Value { get }
  var current: Value { get throws }
  var initialRecord: RouteRecord { get }
  func update(from: Self)
  func apply(
    connection: RouteConnection,
    writeContext: RouterWriteContext
  ) throws
}

// MARK: - OneRouterType

protocol OneRouterType<Value>: RouterType {
  init(
    builder: @escaping () -> Value
  )
}

// MARK: - NRouterType

protocol NRouterType<Element>: RouterType where Value == [Element] {
  associatedtype Element
  init(
    buildKeys: OrderedSet<LSID>,
    builder: @escaping (LSID) throws -> Element
  )
}
