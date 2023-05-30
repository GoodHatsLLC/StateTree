import Foundation
import OrderedCollections
import TreeActor

// MARK: - RouterRuleContext

public struct RouterRuleContext {
  let depth: Int
  let dependencies: DependencyValues
}

// MARK: - RouterType

public protocol RouterType<Value> {
  associatedtype Value
  static var type: RouteType { get }
  var fallback: Value { get }
  var defaultRecord: RouteRecord { get }

  @_spi(Implementation)
  @TreeActor
  func current(at fieldID: FieldID, in: Runtime) throws -> Value
  @_spi(Implementation)
  @TreeActor
  mutating func apply(at fieldID: FieldID, in: Runtime) throws
  @TreeActor
  mutating func update(from: Self)
  @TreeActor
  mutating func assign(
    _ context: RouterRuleContext
  )
  @_spi(Implementation)
  @TreeActor
  mutating func syncToState(field fieldID: FieldID, in: Runtime) throws
}

// MARK: - UnassignedRouterError

struct UnassignedRouterError: Error { }
