import Combine
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain
import ToDoUI

// MARK: - ToDoApp

@main
struct ToDoApp: App {

  // MARK: Internal

  @TreeRoot var root = ToDoList()

  var body: some Scene {
    WindowGroup {
      HStack {
        ToDoListView(list: $root.root)
      }
    }
  }
}

// MARK: - ToDoListView

struct ToDoListView: View {
  @TreeNode var list: ToDoList

  var body: some View {
    Text($list.$filteredToDos.first?.title ?? "first")
      .onTapGesture {
        list.filteredToDos?.first?.title = "OH BOI"
      }
    List($list.$filteredToDos) { node in
      Text(node.title ?? "<no title>").onTapGesture {
        node.title = "LOL\(Int.random(in: .init(1 ... 100)))"
      }
    }
  }
}

//
//  var body: some Scene {
//    WindowGroup {
//      ToDoNavigationView(
//        viewModel: ToDoNavigationViewModel(
//          manager: tree.rootModel,
//          focusProposer: focusProposer
//        )
//      )
//      .whileVisible {
//        try tree.start(options: [.logging(threshold: .info)])
//      }
//      .sheet(isPresented: $debugPresent) {
//        HStack {
//          TextEditor(
//            text: .constant(
//              tree.rootModel.dumpTree { String(describing: $0) }
//                + "\n\n"
//                + tree.debugDescription
//            )
//          )
//          .font(.body.monospaced())
//        }
//      }
//    }
//    .commands {
//      MenuCommands(
//        root: MenuViewModel(
//          manager: tree.rootModel,
//          focusProposer: focusProposer
//        )
//      ) {
//        CommandGroup(after: .sidebar) {
//          Divider()
//          Button {
//            debugPresent = true
//          } label: {
//            Text("Debug Panel")
//          }
//          .keyboardShortcut(.init("p"), modifiers: [.command, .shift])
//        }
//      }
//    }
//  }
//
//  // MARK: Private
//
//  @State private var debugPresent = false
//  @State private var focusProposer = FocusProposer()
//
// }
