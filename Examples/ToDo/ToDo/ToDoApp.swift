import Combine
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain
import ToDoUI

@main
struct ToDoApp: App {
  @StateTree var tree = Tree(
    rootModelState: .init()
  ) { store in
    ToDoManager(store: store)
  }

  var body: some Scene {
    WindowGroup {
      ToDoNavigationView(
        viewModel: ToDoNavigationViewModel(
          manager: tree.rootModel,
          focusProposer: focusProposer
        )
      )
      .whileVisible {
        try tree.start(options: [.logging(threshold: .info)])
      }
      .sheet(isPresented: $debugPresent) {
        HStack {
          TextEditor(
            text: .constant(
              tree.rootModel.dumpTree { String(describing: $0) }
                + "\n\n"
                + tree.debugDescription
            )
          )
          .font(.body.monospaced())
        }
      }
    }
    .commands {
      MenuCommands(
        root: MenuViewModel(
          manager: tree.rootModel,
          focusProposer: focusProposer
        )
      ) {
        CommandGroup(after: .sidebar) {
          Divider()
          Button {
            debugPresent = true
          } label: {
            Text("Debug Panel")
          }
          .keyboardShortcut(.init("p"), modifiers: [.command, .shift])
        }
      }
    }
  }

  @State private var debugPresent = false
  @State private var focusProposer = FocusProposer()

}
