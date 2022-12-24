import GameDomain
import GameUI
import StateTreeSwiftUI
import SwiftUI
import Utilities

// MARK: - TicTacToeApp

@main
@MainActor
struct TicTacToeApp: App {

  @StateTree var tree = Tree(rootModelState: .init()) {
    AppModel(store: $0)
  }

  var body: some Scene {
    WindowGroup {
      TimeTravelView(
        tree: tree,
        options: [.logging(threshold: .info)]
      ) { model in
        AppView(model: model)
      }
    }
    .windowStyle(.hiddenTitleBar)
  }
}
