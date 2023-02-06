// MARK: - RouterType

public protocol RouterType<Value>: Rules {
  associatedtype Value
  init(container: Value, fieldID: FieldID)
  var container: Value { get }

  @TreeActor
  @_spi(Implementation)
  static func value(for record: RouteRecord, in runtime: Runtime) -> Value?
}
