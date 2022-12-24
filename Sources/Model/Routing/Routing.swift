import Dependencies
import Node

// MARK: - Routing

@MainActor
public protocol Routing {

  var models: [any Model] { get }

  /// attach routes to self
  ///
  /// return: whether or not any underlying model attachments changed.
  mutating func attach(parentMeta: StoreMeta) throws -> Bool
  /// detach routes from self
  ///
  /// return: whether or not any underlying model attachments changed.
  mutating func detach() -> Bool
  /// port attachments to the previous onto self, or attach/detach them as appropriate
  ///
  /// return: whether or not any underlying model attachments changed.
  mutating func updateAttachment(from previous: Self, parentMeta: StoreMeta) throws -> Bool
}

extension Routing {
  public func dependency<Value>(
    _ keyPath: WritableKeyPath<DependencyValues, Value>,
    _ value: Value
  )
    -> some Routing
  {
    InjectDependency(into: self) { current in
      current.inserting(keyPath, value: value)
    }
  }
}
