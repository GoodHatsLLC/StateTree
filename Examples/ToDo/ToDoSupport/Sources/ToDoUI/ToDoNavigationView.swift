import Foundation
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain
import UIComponents

// MARK: - ToDoNavigationView

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
      VStack {
        TagView(manager: $todoManager)
      }
    } content: {
      List(
        todoManager.todoList ?? [],
        id: \.id,
        selection: todoManager.$selectedRecord.binding()
      ) { todo in
        NavigationLink(todo.title, value: todo.id)
          .strikethrough(todo.isCompleted)
      }
    } detail: {
      if let selected = $todoManager.$selectedToDo {
        SelectedToDoView(selected: selected)
      } else {
        EmptyView()
      }
    }
    .navigationTitle(
      Text("ToDo")
    )
    .toolbar {
      ToolbarItemGroup {
        Spacer()
      }
      ToolbarItemGroup {
        Button {
          todoManager.createToDo()
        } label: {
          Label("Create", systemImage: "plus.square")
        }
        Button {
          if let id = todoManager.selectedRecord {
            todoManager.deleteToDo(id: id)
          }
        } label: {
          Label("Delete", systemImage: "minus.square")
        }
        .disabled(todoManager.selectedRecord == nil)
      }
    }
  }

  // MARK: Internal

  @TreeNode var todoManager: ToDoManager
  @State var sidebarVisibility: NavigationSplitViewVisibility = .all
}
