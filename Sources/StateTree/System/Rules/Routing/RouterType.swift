import OrderedCollections
import TreeActor

// MARK: - RouterType

public protocol RouterType<Value>: Rules {
  associatedtype Value

  @TreeActor
  @_spi(Implementation)
  static func value(for record: RouteRecord, in runtime: Runtime) throws -> Value
  static var type: RouteType { get }
}

// MARK: - RouteDefaultFailure

struct RouteDefaultFailure: Error { }

// MARK: - InvalidRouteRecordError

struct InvalidRouteRecordError: Error { }

// MARK: - OneRouterType

public protocol OneRouterType<Value>: RouterType {
  init(builder: @escaping () -> Value, fieldID: FieldID)
  var builder: () -> Value { get }
}

// MARK: - NRouterType

public protocol NRouterType<NodeType>: RouterType where Value == [NodeType] {
  associatedtype NodeType: Node
  init(ids: OrderedSet<LSID>, builder: @escaping (LSID) -> NodeType, fieldID: FieldID)
  var builder: (LSID) -> NodeType { get }
}
