import Dependencies
import Emitter
import Foundation
import Model
import Node
import Projection

// MARK: - TestModel

struct TestModel: Model {

  init(store: Store<Self>) {
    self.store = store
  }

  struct State: ModelState {
    var someString = ""
    var someOtherString = ""
    var twoState: TwoModel.State?
  }

  let store: Store<Self>

  @Route<TwoModel> var two
  @Route<ThreeModel> var three
  @Route<TestModel> var test
  @Dependency(\.testOne) var depOne
  @Dependency(\.testTwo) var depTwo

  func route(state: Projection<State>) -> some Routing {
    if let state = state.twoState.compact() {
      $two.route(state) { store in
        .init(store: store)
      }
      .dependency(\.testOne, "INJECTED_VALUE_TWO")
    } else {
      let threeState = state.statefulMap(into: ThreeModel.State()) { _, _ in }
      $three.route(threeState) { store in
        ThreeModel(store: store)
      }
      .dependency(\.testOne, "INJECTED_VALUE_THREE")
    }

    if state.value.someString.hasPrefix("Loop") {
      let nextState = state.statefulMap(into: TestModel.State()) { from, to in
        let dropped = from.someString.map { "\($0.dropFirst(4))" }
        dropped --> to.someString
      }
      $test.route(nextState) { store in
        .init(store: store)
      }
    }
  }

}

// MARK: - ThreeModel

struct ThreeModel: Model {
  struct State: ModelState {}
  init(store: Store<Self>) {
    self.store = store
  }

  let store: Store<Self>

  @Dependency(\.testOne) var fieldOne
  @Dependency(\.testTwo) var fieldTwo

  @RouteBuilder
  func route(state _: Projection<State>) -> some Routing {
    _ = 5
  }
}

// MARK: - TwoModel

struct TwoModel: Model {
  struct State: ModelState {}
  init(store: Store<Self>) {
    self.store = store
  }

  let store: Store<Self>

  @Dependency(\.testOne) var propertyOne
  @Dependency(\.testTwo) var propertyTwo

  @RouteBuilder
  func route(state _: Projection<State>) -> some Routing {
    VoidRoute()
  }
}
