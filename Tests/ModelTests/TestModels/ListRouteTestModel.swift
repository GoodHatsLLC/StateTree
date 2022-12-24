import Dependencies
import Emitter
import Foundation
import Model
import Node
import Projection

// MARK: - ListRouteTestModel

struct ListRouteTestModel: Model {

  init(store: Store<Self>) {
    self.store = store
  }

  struct State: ModelState {
    var submodelInfo: [IDModel.State]
  }

  let store: Store<Self>

  func add(_ value: String) {
    store.transaction { state in
      state.submodelInfo
        .append(
          .init(sharedState: value)
        )
    }
  }

  func edit(id: UUID, value: String) {
    store.transaction { state in
      if let index = state.submodelInfo
        .firstIndex(where: { $0.id == id })
      {
        state.submodelInfo[index].sharedState = value
      }
    }
  }

  func remove(id removeID: UUID) {
    store.transaction { state in
      state.submodelInfo
        .removeAll { state in
          state.id == removeID
        }
    }
  }

  func value(id: UUID, value _: String) -> String? {
    store.read.submodelInfo
      .first { $0.id == id }
      .map(\.sharedState)
  }

  @RouteList<IDModel> var identifiableModels

  func route(state: Projection<State>) -> some Routing {
    let items = state.submodelInfo

    $identifiableModels
      .routeForEach(
        items
      ) { _, store in
        .init(store: store)
      }
  }

}

// MARK: - IDModel

struct IDModel: Model, Identifiable {

  struct State: ModelState, Identifiable {
    var id: UUID = .init()
    var sharedState = ""
  }

  init(store: Store<Self>) {
    self.store = store
  }

  var value: String {
    store.read.sharedState
  }

  let store: Store<Self>

  @RouteBuilder
  func route(state _: Projection<State>) -> some Routing {
    VoidRoute()
  }
}
