import StateTreeSwiftUI
import SwiftUI
import TicTacToeDomain

// MARK: - RootView

struct RootView: View {

  var body: some View {
    VStack(alignment: .center, spacing: 2.su) {
      if let gameInfo = $model.$gameOrSignIn.a {
        LoggedInView(model: gameInfo)
      } else if let loggedOut = $model.$gameOrSignIn.b {
        LoggedOutView(model: loggedOut)
      }
    }
  }

  @TreeNode var model: AppNode

}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {

  @PreviewNode static var root = AppNode()

  static var previews: some View {
    RootView(model: $root)
      .fixedSize()
  }
}
