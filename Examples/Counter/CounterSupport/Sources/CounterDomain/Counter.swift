import Foundation
import StateTree

public struct Counter: Model, Identifiable {
  public init(store: Store<Self>) {
    self.store = store
  }

  /// State for the `Counter` model.
  ///
  /// This struct is marked `Identifiable` to allow the `Counter`
  /// to be used as a list item.
  public struct State: ModelState, Identifiable {
    public var id: Int
    public var count: Int
  }

  public let store: Store<Self>

  /// The `Controls` sub-model exposes increment/decrement functionality
  /// to our consumers, the UI layer.
  @Route public var controls: Controls?

  /// An identifying emoji created from our state `id`.
  public var emoji: Emoji {
    Emoji.hash(of: id)
  }

  /// The count we're representing to the UI layer.
  public var count: Int {
    store.read.count
  }

  @RouteBuilder
  public func route(state: Projection<State>) -> some Routing {
    // We make a new `Projection<Controls.State>` from our
    // state by mapping our state into it.
    //
    // `Controls.State()` is instantiated with its default
    // values but its fields are bound to our `State`'s fields.
    //
    // We use bidirectional field bindings `<->` so that
    // state changes made by the `Controls` model to its state
    // are propagated back to this model.
    //
    // By routing to it in this way we describe the connect
    // between the `Controls` model's underlying state and our own.
    //
    // StateTree keeps the values in sync based on this definition.
    $controls
      .route(state, into: .init()) { from, to in
        from.id <-> to.id
        from.count <-> to.count
      } model: { store in
        Controls(store: store)
      }
  }
}
