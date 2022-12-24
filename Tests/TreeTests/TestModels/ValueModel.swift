import Emitter
import Foundation
import Model
import Node
import Projection

// MARK: - ValueModel

struct ValueModel: Model {

  // MARK: Lifecycle

  init(store: Store<Self>) {
    self.store = store
  }

  // MARK: Internal

  struct State: ModelState {
    var value = ""
  }

  let store: Store<Self>

  func route(state _: Projection<State>) -> some Routing {}

}
