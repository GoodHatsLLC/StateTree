import StateTree

public struct Controls: Model {
  public init(store: Store<Self>) {
    self.store = store
  }

  public struct State: ModelState {
    public init() {}
    var id = 0
    var count = 0
  }

  public let store: Store<Self>

  /// Increment the counter value
  public func increment() {
    store.transaction { state in
      state.count += 1
    }
  }

  /// Decrement the counter value
  public func decrement() {
    store.transaction { state in
      state.count -= 1
    }
  }

  /// `route(state:)` is required for `Model` conformance, but
  /// can simply be left empty.
  ///
  /// Note:
  /// `Model` uses a `@RouteBuilder` for this method. The `@RouteBuilder`
  /// generates a `VoidRoute` given an empty payload.
  @RouteBuilder
  public func route(state _: Projection<State>) -> some Routing {}
}
