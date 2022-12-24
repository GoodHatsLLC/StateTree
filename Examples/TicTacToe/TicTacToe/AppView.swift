import Game
import StateTreeSwiftUI
import SwiftUI

// MARK: - AppView

struct AppView: View {

  init(model: ModelObject<AppStateTree>) {
    self.model = model
  }

  @ObservedObject var model: ModelObject<AppStateTree>

  var body: some View {
    VStack {
      ForEach(model.routes) { route in
        switch route.route {
        case .login(let model):
          EmptyView()
        case .board(let model):
          EmptyView()
        }
      }
      EmptyView()
    }
    .padding()
  }
}

// MARK: - AppView_Previews

struct AppView_Previews: PreviewProvider {
  static var model = ModelObject(model: AppStateTree(store: .init(routeID: .rootID())))
  static var previews: some View {
    AppView(model: model)
  }
}
