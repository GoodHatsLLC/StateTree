// import StateTreeSwiftUI
// import SwiftUI
// import ToDoDomain
// import UIComponents
//
//// MARK: - ToDoListView
//
// struct ToDoListView: View {
//
//  // We must provide an direct binding to SwiftUI
//  // to avoid update bugs.
//  // We use this intermediate UI state.
//  @State var selectionID: UUID?
//  @FocusState var searchFocus
//  @FocusState var listFocus
//  @FocusState var todoFocusID: UUID?
//  @ObservedObject var viewModel: ToDoListViewModel
//
//  var body: some View {
//    Section {
//      VStack(alignment: .center, spacing: 0) {
//        List(selection: $selectionID) {
//          if !viewModel.resultsAreEmpty {
//            ForEach(viewModel.todos) { todo in
//              NavigationLink(value: todo.id) {
//                HStack {
//                  Image(
//                    systemName:
//                      viewModel
//                      .checkmarkImageName(
//                        isCompleted: todo.completionData.isCompleted
//                      )
//                  )
//                  .foregroundColor(
//                    viewModel
//                      .foregroundColor(
//                        todoID: todo.id
//                      )
//                  )
//                  Label(
//                    todo.titleData.title ?? "…",
//                    systemImage: ""
//                  )
//                  .labelStyle(.titleOnly)
//                  Spacer()
//                }
//              }
//              .focused($todoFocusID, equals: todo.id)
//              .swipeActions(
//                edge: .leading,
//                allowsFullSwipe: true
//              ) {
//                Button("Delete", role: .destructive) {
//                  viewModel.delete(todoID: todo.id)
//                }
//                .tint(.gray)
//              }
//              .swipeActions(
//                edge: .trailing,
//                allowsFullSwipe: true
//              ) {
//                Button(
//                  todo.completionData.isCompleted
//                    ? "Undo Complete"
//                    : "Complete",
//                  role: .cancel
//                ) {
//                  viewModel
//                    .toggleIsCompleted(
//                      todoID: todo.id
//                    )
//                }
//                .tint(
//                  todo.completionData.isCompleted
//                    ? .orange
//                    : .mint
//                )
//              }
//            }
//          } else {
//            NavigationLink(value: UUID.null) {
//              VStack(alignment: .center) {
//                Text("🔍")
//                if viewModel.filter.type == .all,
//                  viewModel.filter.query.textQuery.isEmpty
//                {
//                  Text("You have no ToDos!")
//                  Button("Make one?") {
//                    viewModel.createToDo()
//                  }
//                } else {
//                  Text("No unfiltered ToDos")
//                  Button("Clear filters?") {
//                    viewModel.clearFilters()
//                  }
//                }
//              }
//              .opacity(0.5)
//              .frame(maxWidth: .infinity)
//            }
//          }
//        }
//        .focusSection()
//        .focused($listFocus)
//      }
//      .frame(maxHeight: .infinity)
//    } header: {
//      VStack(alignment: .leading, spacing: 0) {
//        HStack(spacing: 0) {
//          switch viewModel.filter.query {
//          case .text,
//            .none:
//            CapsuleSearchField(
//              text: $viewModel.filter.query.textQuery,
//              prompt: viewModel.filter.type.text + "…"
//            )
//            .frame(height: 24)
//            .padding([.top], 8)
//          case .toggle:
//            HStack(spacing: 0) {
//              Toggle(isOn: $viewModel.filter.query.toggleQuery) {
//                Text(viewModel.filter.type.text)
//                  .font(.callout.monospaced())
//              }
//              Spacer()
//            }
//            .frame(height: 24)
//            .padding([.top, .horizontal], 8)
//          case .date:
//            DatePicker(
//              viewModel.filter.type.shortText,
//              selection: $viewModel.filter.query.dateQuery,
//              displayedComponents: [.date]
//            )
//            .datePickerStyle(.compact)
//            .font(.callout.monospaced())
//            .frame(height: 24)
//            .padding([.top, .horizontal], 8)
//          }
//        }
//      }
//      .focusSection()
//      .focused($searchFocus)
//    }
//    .frame(maxWidth: .infinity)
//    .onChange(of: selectionID) { id in
//      if let id {
//        // report visual selection to viewModel
//        viewModel.proposeToDoSelection(id: id)
//      }
//    }
//    .onReceive(viewModel.focusProposer.todosFocus) { focus in
//      switch focus {
//      case nil:
//        searchFocus = false
//        todoFocusID = nil
//      case .todo(let id):
//        searchFocus = false
//        todoFocusID = id
//        selectionID = id
//      case .any:
//        searchFocus = false
//        listFocus = true
//
//        if let id = viewModel.selectedToDoID
//          ?? viewModel.todos.first?.id
//        {
//          todoFocusID = id
//          selectionID = id
//        } else {
//          todoFocusID = nil
//        }
//      case .find:
//        searchFocus = true
//        todoFocusID = nil
//      }
//    }
//  }
//
// }
//
//// MARK: - ToDoListView_Previews
//
// struct ToDoListView_Previews: PreviewProvider {
//
//  static var previews: some View {
//    ToDoListView(
//      viewModel: .preview(
//        state: ToDoList.State(),
//        model: { store in
//          ToDoList(store: store)
//        },
//        viewModel: { model in
//          ToDoListViewModel(
//            model: model,
//            manager: .init(
//              store: .init(
//                rootState: .init()
//              )
//            ),
//            focusProposer: FocusProposer()
//          )
//        }
//      )
//    )
//  }
// }
