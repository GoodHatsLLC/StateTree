import Combine
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain
import ToDoUI

// MARK: - ToDoApp

@main
struct ToDoApp: App {

  // MARK: Internal

  @TreeRoot var tree = ToDoList()

  var body: some Scene {
    WindowGroup {
      HStack {
        ToDoListView(test: Test(root: $tree.root))
      }
    }
  }
}

// MARK: - Test

class Test: ObservableObject {

  // MARK: Lifecycle

  init(root: TreeNode<ToDoList>) {
    _root = .init(projectedValue: root)
  }

  // MARK: Internal

  @PublishedNode var root: ToDoList
}

// MARK: - ToDoListView

struct ToDoListView: View {
  @StateObject var test: Test

  var body: some View {
    Text(test.root.filteredToDos?.first?.title ?? "first")
      .onTapGesture {
        test.root.filteredToDos?.first?.title = "OH BOI"
      }
    List(test.$root.$filteredToDos) { node in
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
