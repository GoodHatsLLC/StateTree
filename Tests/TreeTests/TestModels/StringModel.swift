import Emitter
import Foundation
import Model
import Node
import Projection

// MARK: - StringModel

struct StringModel: Model {

  // MARK: Lifecycle

  init(store: Store<Self>) {
    self.store = store
  }

  // MARK: Internal

  struct State: ModelState {
    var string = ""
    var otherString = ""
    var value = ""
  }

  let store: Store<Self>

  func route(state _: Projection<State>) -> some Routing {}

}
