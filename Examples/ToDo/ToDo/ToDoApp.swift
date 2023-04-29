import Combine
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain
import ToDoUI

// MARK: - ToDoApp

@main
struct ToDoApp: App {

  // MARK: Internal

  @TreeRoot var tree = ToDoManager()

  var body: some Scene {
    WindowGroup {
      ToDoNavigationView(todoManager: $tree.root)
    }
  }
}
