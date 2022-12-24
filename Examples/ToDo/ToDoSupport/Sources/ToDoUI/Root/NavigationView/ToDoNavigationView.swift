import Foundation
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain

public struct ToDoNavigationView: View {

  public init(
    viewModel: ToDoNavigationViewModel
  ) {
    self.viewModel = viewModel
  }

  public var body: some View {
    NavigationSplitView(
      columnVisibility: $sidebarVisibility
    ) {
      FilterListView(
        viewModel: viewModel.metadataListViewModel
      )
      .focused($focus, equals: .filters)
    } content: {
      VStack {
        if let list = viewModel.listViewModel {
          ToDoListView(
            viewModel: list
          )
          .focused($focus, equals: .todos)
        }
      }
    } detail: {
      if let selected = viewModel.selectedViewModel {
        SelectedToDoView(
          viewModel: selected
        )
        .focused($focus, equals: .selected)
      } else {
        VStack(alignment: .center) {
          Text("☑️")
          Text("No ToDo selected")
        }
        .opacity(0.5)
      }
    }
    .navigationTitle(
      Text(viewModel.title ?? "ToDo")
    )
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        Button {
          viewModel.createToDo()
        } label: {
          Label("Create", systemImage: "plus.app")
        }
        Button {
          viewModel.deleteSelection()
        } label: {
          Label("Delete", systemImage: "minus.square")
        }
        .disabled(!viewModel.allowDeleteSelection)
      }
    }
  }

  @FocusState var focus: AppFocus.NavigationFocus?
  @State var sidebarVisibility: NavigationSplitViewVisibility = .all
  @ObservedObject var viewModel: ToDoNavigationViewModel
}
