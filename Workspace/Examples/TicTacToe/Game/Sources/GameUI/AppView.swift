import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - AppView

public struct AppView: View {

  public init() { }

  public var body: some View {
    PlaybackView(root: $root) { node in
      RootView(model: node)
    }
  }

  @TreeRoot var root = AppModel()

}

// MARK: - AppView_Previews

struct AppView_Previews: PreviewProvider {

//  @PreviewNode static var gameInfo = AppModel()

  static var previews: some View {
    AppView()
  }
}
