import Foundation
import Node
import Utilities

// MARK: - VoidRoute

public struct VoidRoute: Routing {
  public mutating func attach(parentMeta _: StoreMeta) throws -> Bool { false }

  public mutating func detach() -> Bool { false }

  public mutating func updateAttachment(
    from _: VoidRoute,
    parentMeta _: StoreMeta
  ) throws
    -> Bool
  { false }

  nonisolated public init() {}
  public let models: [any Model] = []
}
