import StateTreeSwiftUI
import SwiftUI
import TicTacToeDomain

// MARK: - AppView

public struct AppView: View {

  public init() { }

  @TreeRoot var root = AppNode()

  public var body: some View {
    PlaybackView(root: $root) { node in
      RootView(model: node)
    }
  }

}

// MARK: - AppView_Previews

struct AppView_Previews: PreviewProvider {

  static var previews: some View {
    AppView()
  }
}
