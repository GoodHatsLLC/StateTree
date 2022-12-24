import Foundation
import Node
import Utilities

// MARK: - MaybeRoute

public struct MaybeRoute<R: Routing>: Routing {

  public var models: [any Model] {
    optionalRoutes.map { $0.models } ?? []
  }

  public mutating func attach(parentMeta: StoreMeta) throws -> Bool {
    (try optionalRoutes?.attach(parentMeta: parentMeta)) ?? false
  }

  public mutating func detach() -> Bool {
    (optionalRoutes?.detach()) ?? false
  }

  public mutating func updateAttachment(
    from previous: MaybeRoute<R>,
    parentMeta: StoreMeta
  ) throws
    -> Bool
  {
    guard var prev = previous.optionalRoutes
    else {
      return try attach(parentMeta: parentMeta)
    }
    guard var newRoutes = optionalRoutes  // FIXME: unexpected hit — in second of only one expected rout acts
    else {
      return prev.detach()
    }
    let didUpdate = try newRoutes.updateAttachment(from: prev, parentMeta: parentMeta)
    optionalRoutes = newRoutes
    return didUpdate
  }

  var optionalRoutes: R?

}
