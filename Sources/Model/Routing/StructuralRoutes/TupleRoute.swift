import Foundation
import Node
import Utilities

// MARK: - TupleRoute

public struct TupleRoute<M1: Routing, M2: Routing>: Routing {

  public var models: [any Model] { [route1.models, route2.models].flatMap { $0 } }

  public mutating func attach(parentMeta: StoreMeta) throws -> Bool {
    let a = try route1.attach(parentMeta: parentMeta)
    let b = try route2.attach(parentMeta: parentMeta)
    return a || b
  }

  public mutating func detach() -> Bool {
    let a = route1.detach()
    let b = route2.detach()
    return a || b
  }

  public mutating func updateAttachment(
    from previous: TupleRoute<M1, M2>,
    parentMeta: StoreMeta
  ) throws
    -> Bool
  {
    let a = try route1.updateAttachment(from: previous.route1, parentMeta: parentMeta)
    let b = try route2.updateAttachment(from: previous.route2, parentMeta: parentMeta)
    return a || b
  }

  var route1: M1
  var route2: M2
}
