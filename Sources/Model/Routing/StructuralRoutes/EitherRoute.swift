import Foundation
import Node
import Utilities

// MARK: - EitherRoute

public enum EitherRoute<RA: Routing, RB: Routing>: Routing {
  case routesA(RA)
  case routesB(RB)

  public var models: [any Model] {
    switch self {
    case .routesA(let routes): return routes.models
    case .routesB(let routes): return routes.models
    }
  }

  public mutating func attach(parentMeta: StoreMeta) throws -> Bool {
    switch self {
    case .routesA(var a):
      let didAttach = try a.attach(parentMeta: parentMeta)
      self = .routesA(a)
      return didAttach
    case .routesB(var b):
      let didAttach = try b.attach(parentMeta: parentMeta)
      self = .routesB(b)
      return didAttach
    }
  }

  public mutating func detach() -> Bool {
    switch self {
    case .routesA(var a):
      let didDetach = a.detach()
      self = .routesA(a)
      return didDetach
    case .routesB(var b):
      let didDetach = b.detach()
      self = .routesB(b)
      return didDetach
    }
  }

  public mutating func updateAttachment(
    from previous: Self,
    parentMeta: StoreMeta
  ) throws
    -> Bool
  {
    switch (previous, self) {
    case (.routesA(let prev), .routesA(var new)):
      let didUpdate = try new.updateAttachment(from: prev, parentMeta: parentMeta)
      self = .routesA(new)
      return didUpdate
    case (.routesB(let prev), .routesB(var new)):
      let didUpdate = try new.updateAttachment(from: prev, parentMeta: parentMeta)
      self = .routesB(new)
      return didUpdate
    case (.routesA(var prev), .routesB(var new)):
      let detach = prev.detach()
      let attach = try new.attach(parentMeta: parentMeta)
      self = .routesB(new)
      // we've changed our attachments if we've attached or detached any sub-routes
      return detach || attach
    case (.routesB(var prev), .routesA(var new)):
      let detach = prev.detach()
      let attach = try new.attach(parentMeta: parentMeta)
      self = .routesA(new)
      // we've changed our attachments if we've attached or detached any sub-routes
      return detach || attach
    }
  }
}
