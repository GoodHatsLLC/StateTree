import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - AppView

public struct AppView: View {

  public init() { }

  @TreeRoot var root = AppModel()

  public var body: some View {
    RootView(model: $root.root)
  }

}

// MARK: - AppView_Previews

struct AppView_Previews: PreviewProvider {

//  @PreviewNode static var gameInfo = AppModel()

  static var previews: some View {
    AppView()
  }
}
