import StateTreeSwiftUI
import SwiftUI
import TicTacToeDomain

// MARK: - AppView

public struct AppView: View {

  public init() { }

  @TreeRoot var root = AppModel()

  public var body: some View {
    PlaybackView(root: $root) { _ in
      RootView(model: $root.root)
    }
  }

}

// MARK: - AppView_Previews

struct AppView_Previews: PreviewProvider {

//  @PreviewNode static var gameInfo = AppModel()

  static var previews: some View {
    AppView()
  }
}
