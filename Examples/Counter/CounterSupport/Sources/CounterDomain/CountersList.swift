import StateTree

public struct CountersList: Model {
  public init(store: Store<Self>) {
    self.store = store
  }

  /// State owned by this model and used to populate the `CountersListViewController`.
  public struct State: ModelState {
    public init() {}

    /// The state for all active counters.
    /// This is directly mapped into, and so is the source of truth for,
    /// the state in the `Counter` models.
    var counters: [Counter.State] = []

    /// The index of a counter in the state list, set when drilling down into it.
    var selected: Int?

    /// An incrementing count of the created counters which is used to assign a stable ID
    /// (and converted to the Emoji)
    var maxID = 0
  }

  public let store: Store<Self>

  /// Model representations of all active counters
  ///
  /// Note:
  /// This implementation chooses to route to all active
  /// counters at all times and to highlight the selected one
  /// on a non-`@Route` field.
  /// This lets us represent all counters as the same type of
  /// `Counter` model.
  /// It's a bit arbitrary. It seems equally appropriate
  /// to represent only the selected counter as a route.
  @RouteList public var counters: [Counter]

  /// The active counter to drill down into as defined by the `selected`
  /// state field value.
  public var selected: Counter? {
    counters
      .first { $0.id == store.read.selected }
  }

  /// Add a counter assigning it an `id` matching the current
  /// `maxID`. Then increment that id.
  ///
  /// Note:
  /// As with SwiftUI's collection based views, models used in lists must have
  /// `State` conforming to `Identifiable`.
  /// The `id` fills this conformance requirement.
  ///
  /// Models with `Identifiable` state also surface that the state's `id`
  /// as their own `id` field — so that they can easily also be conformed to
  /// `Identifiable`.
  public func addCounter() {
    store
      .transaction { state in
        state
          .counters
          .append(.init(id: state.maxID, count: 0))
        state.maxID += 1
      }
  }

  /// Remove a counter by removing the `State` value backing it.
  ///
  /// Note:
  /// Since this model's `counters` field is directly mapped into
  /// its submodels with `routeForEach` those submodels
  /// are immediately invalidated and removed from the this struct's
  /// `@RouteList` `counters` field.
  /// (If a consumer were to hold an invalidated copy of a `Counter`
  /// edits to it would not propagate to any of our valid state here.)
  public func removeCounter(_ counter: Counter) {
    store.transaction { state in
      state.counters
        .removeAll { $0.id == counter.id }
    }
  }

  /// Select a counter, setting our selected state to be its `id`.
  public func select(counter: Counter?) {
    store.transaction { state in
      state.selected =
        state.counters
        .first { $0.id == counter?.id }?
        .id
    }
  }

  @RouteBuilder
  public func route(state: Projection<State>) -> some Routing {
    $counters
      .routeForEach(
        state.counters
      ) { _, store in
        Counter(store: store)
      }
  }

}
