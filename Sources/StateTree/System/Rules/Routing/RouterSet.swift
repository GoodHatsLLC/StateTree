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
  func syncToState() throws {
    for router in routers {
      try router.syncToState()
    }
  }
}
