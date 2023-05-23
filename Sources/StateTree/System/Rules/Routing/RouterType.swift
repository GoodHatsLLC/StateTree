import Foundation
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
  var defaultRecord: RouteRecord { get }
  @TreeActor var current: Value { get throws }
  @TreeActor
  mutating func apply(
    connection: RouteConnection,
    writeContext: RouterWriteContext
  ) throws
  @TreeActor
  mutating func update(from: Self)
}
