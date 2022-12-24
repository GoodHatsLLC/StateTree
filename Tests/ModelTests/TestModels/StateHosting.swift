import Dependencies
import Emitter
import Foundation
import Model
import Node
import Projection

enum StateHosting {

  struct Root: Model {

    struct State: ModelState {
      var counter = 0
    }

    let store: Store<Self>

    var counter: Int {
      get {
        store.read.counter
      }
      set {
        store.transaction { state in
          state.counter = newValue
        }
      }
    }

    @Route<Leaf> var leaf

    func route(state: Projection<State>) -> some Routing {
      $leaf.route(state, into: Leaf.State()) { from, to in
        from.counter <-> to.counter
      } model: { store in
        Leaf(store: store)
      }
    }

  }

  struct Leaf: Model {
    struct State: ModelState {
      var counter = 0
      var value = "LEAF_DEFAULT"
    }

    let store: Store<Self>

    var counter: Int {
      get {
        store.read.counter
      }
      set {
        store.transaction { state in
          state.counter = newValue
        }
      }
    }

    var value: String {
      get {
        store.read.value
      }
      set {
        store.transaction { state in
          state.value = newValue
        }
      }
    }

    func setValueIncrementingCounter(_ value: String) {
      store.transaction { state in
        state.counter += 1
        state.value = value
      }
    }

    func route(state _: Projection<State>) -> some Routing {}
  }

}
