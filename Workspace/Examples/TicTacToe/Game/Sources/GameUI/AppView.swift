import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - AppView

public struct AppView: View {

  public init() { }

  public var body: some View {
    TimeTravelView(root: $root) { node in
      RootView(model: node)
    }
  }

  @TreeRoot var root = AppModel()

}
