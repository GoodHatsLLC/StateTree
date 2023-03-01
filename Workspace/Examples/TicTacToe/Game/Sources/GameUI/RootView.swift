import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - RootView

struct RootView: View {

  var body: some View {
    VStack(alignment: .center, spacing: 2.su) {
      if let gameInfo = $model.$loggedIn {
        LoggedInView(model: gameInfo)
      } else if let loggedOut = $model.$loggedOut {
        LoggedOutView(model: loggedOut)
      }
    }
  }

  @TreeNode var model: AppModel

}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {

  @PreviewNode static var root = AppModel()

  static var previews: some View {
    RootView(model: $root)
      .fixedSize()
  }
}
