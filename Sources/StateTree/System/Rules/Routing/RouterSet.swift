import TreeActor

struct RouterSet {
  var routers: [any RouteHandle] = []

  @TreeActor
  func apply() throws {
    for router in routers {
      try router.apply()
    }
  }

  @TreeActor
  func syncToState() throws -> [AnyScope] {
    try routers.reduce(into: [AnyScope]()) { partialResult, handle in
      try partialResult.append(contentsOf: handle.syncToState())
    }
  }
}
