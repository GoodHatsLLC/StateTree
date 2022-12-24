import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - AppView

public struct AppView: View {

  public init(model: AppModel) {
    observed = model
  }

  public var body: some View {
    VStack(alignment: .center, spacing: 2.su) {
      if let gameInfo = observed.loggedIn {
        LoggedInView(model: gameInfo)
      } else if let loggedOut = observed.loggedOut {
        LoggedOutView(model: loggedOut)
      }
    }
    .aspectRatio(1, contentMode: .fit)
  }

  @ObservedModel var observed: AppModel

}

// MARK: - AppView_Previews

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(
      model: .preview(
        state: .init(
          authentication: nil
        )
      ) { store in
        AppModel(store: store)
      }
    )
    AppView(
      model: .preview(
        state: .init(
          authentication: .init(
            userName: "yolo",
            token: "some-token"
          )
        )
      ) { store in
        AppModel(store: store)
      }
    )
  }
}
