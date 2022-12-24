import Dependencies
import Emitter
import Foundation
import Model
import Node
import Projection

enum PartialMapping {

  struct BaseModel: Model {

    struct State: ModelState {
      var depth = 2
      var value = "DEFAULT"
    }

    let store: Store<Self>

    @Route<IntermediateModel> var next

    func route(state: Projection<State>) -> some Routing {
      $next.route(state, into: .init()) { from, to in
        from.value <-- to.value
        from.value.map { _ in "DEFAULT" } --> to.value
        from.depth --> to.depth
      } model: { store in
        IntermediateModel(store: store)
      }
    }
  }

  struct IntermediateModel: Model {
    struct State: ModelState {
      var depth = 0
      var value = "DEFAULT"
    }

    let store: Store<Self>

    @Route<IntermediateModel> var next
    @Route<LeafModel> var leaf

    func route(state: Projection<State>) -> some Routing {
      if state.value.depth > 0 {
        $next.route(state, into: .init()) { from, to in
          let decremented = from.map { $0.depth - 1 }
          decremented --> to.depth
          from.value <-- to.value
          from.value --> to.value
        } model: { store in
          .init(store: store)
        }

      } else {
        $leaf.route(state, into: .init()) { from, to in
          from.value <-- to.value
        } model: { store in
          .init(store: store)
        }
      }
    }
  }

  struct LeafModel: Model {
    struct State: ModelState {
      var value = "LEAF_DEFAULT"
    }

    let store: Store<Self>

    func route(state _: Projection<State>) -> some Routing {}
  }

}
