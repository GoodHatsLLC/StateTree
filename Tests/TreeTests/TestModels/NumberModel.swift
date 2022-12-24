import Emitter
import Foundation
import Model
import Node
import Projection

// MARK: - NumberModel

struct NumberModel: Model {

  init(store: Store<Self>) {
    self.store = store
  }

  struct State: ModelState, Identifiable {
    var number = 0
    var id: String { "\(number)" }
    var value = ""
  }

  @Route<ValueModel> var valueModel

  let store: Store<Self>

  func route(state: Projection<State>) -> some Routing {
    let valueState = state.statefulMap(into: ValueModel.State()) { from, to in
      from.value --> to.value
    }
    $valueModel.route(valueState) { store in
      ValueModel(store: store)
    }
  }
}
