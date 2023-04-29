import Foundation
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain

public struct ToDoNavigationView: View {

  // MARK: Lifecycle

  public init(todoManager: TreeNode<ToDoManager>) {
    _todoManager = todoManager
  }

  // MARK: Public

  public var body: some View {
    NavigationSplitView(
      columnVisibility: $sidebarVisibility
    ) {
      Text("Sidebar")
    } content: {
      List(todoManager.todos ?? []) { todo in
        Text(todo.title)
      }
    } detail: {
      Text("Detail")
    }
    .navigationTitle(
      Text("ToDo")
    )
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        Button {
          todoManager.createToDo(title: "Test")
        } label: {
          Label("Create", systemImage: "plus.app")
        }
        Button { } label: {
          Label("Delete", systemImage: "minus.square")
        }
      }
    }
    .onAppear {
      todoManager.reloadAll()
    }
  }

  // MARK: Internal

  @TreeNode var todoManager: ToDoManager
  @State var sidebarVisibility: NavigationSplitViewVisibility = .all
}
