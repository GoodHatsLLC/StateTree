import Dependencies
import Emitter
import Foundation
import Model
import Node
import Projection

enum ChangeRoot {

  struct Root: Model {

    init(store: Store<Self>) {
      _counter = store.proxy(\.counter)
      self.store = store
    }

    struct State: ModelState {
      var counter = 0
    }

    let store: Store<Self>

    @StoreValue var counter: Int

    @Route<Trunk> var trunk

    func route(state: Projection<State>) -> some Routing {
      $trunk.route(state, into: Trunk.State()) { from, to in
        from.counter <-> to.counter
      } model: { store in
        Trunk(store: store)
      }
    }
  }

  struct Trunk: Model {

    init(store: Store<Self>) {
      _counter = store.proxy(\.counter)
      self.store = store
    }

    struct State: ModelState {
      var counter = 0
    }

    let store: Store<Self>

    @StoreValue var counter: Int

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
    init(store: Store<Self>) {
      _counter = store.proxy(\.counter)
      _value = store.proxy(\.value)
      self.store = store
    }

    struct State: ModelState {
      var counter = 0
      var value = "LEAF_DEFAULT"
    }

    let store: Store<Self>

    @StoreValue var counter: Int
    @StoreValue var value: String

    func setValueIncrementingCounter(_ value: String) {
      store.transaction { state in
        state.counter += 1
        state.value = value
      }
    }

    func route(state _: Projection<State>) -> some Routing {}
  }

}
