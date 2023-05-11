import Combine
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain
import ToDoUI

// MARK: - ToDoApp

@main
struct ToDoApp: App {

  // MARK: Internal

  /// Uncomment to use default data
  @TreeRoot(state: DefaultState.state, rootNode: ToDoManager()) var root

  // Uncomment to run the demo from a blank state:
//   @TreeRoot var root = ToDoManager()

  var body: some Scene {
    WindowGroup {
      ToDoNavigationView(todoManager: $root.node)
        .onDisappear {
          print(try! $root.tree.assume.snapshot().formattedJSON)
        }
    }
  }
}

// MARK: - DefaultState

enum DefaultState {
  static var state: TreeStateRecord {
    if let filePath = Bundle.main.path(forResource: "payload", ofType: "json") {
      do {
        let contents = try String(contentsOfFile: filePath)
        let state = try TreeStateRecord(formattedJSON: contents)
        return state
      } catch {
        fatalError(error.localizedDescription)
      }
    } else {
      fatalError("bad")
    }
  }

}
