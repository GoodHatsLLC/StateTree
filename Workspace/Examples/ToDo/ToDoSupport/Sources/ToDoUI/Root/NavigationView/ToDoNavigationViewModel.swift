// import Combine
// import Foundation
// import StateTree
// import StateTreeSwiftUI
// import ToDoDomain
//
// public final class ToDoNavigationViewModel: ObservableObject {
//  public init(
//    manager: ToDoManager,
//    focusProposer: FocusProposer
//  ) {
//    self.manager = manager
//    self.focusProposer = focusProposer
//  }
//
//  let focusProposer: FocusProposer
//
//  var listViewModel: ToDoListViewModel? {
//    manager
//      .list
//      .map {
//        .init(
//          model: $0,
//          manager: manager,
//          focusProposer: focusProposer
//        )
//      }
//  }
//
//  var selectedViewModel: SelectedToDoViewModel? {
//    manager
//      .selectedToDo
//      .map {
//        .init(
//          model: $0,
//          focusProposer: focusProposer
//        )
//      }
//  }
//
//  var metadataListViewModel: FilterListViewModel {
//    .init(
//      manager: manager,
//      focusProposer: focusProposer
//    )
//  }
//
//  var title: String? {
//    manager
//      .selectedToDo
//      .flatMap { $0.title }
//      ?? "ToDos"
//  }
//
//  var filter: SearchFilter {
//    get { manager.filter }
//    set { manager.filter = newValue }
//  }
//
//  var allowDeleteSelection: Bool {
//    manager.selectedToDo?.id != nil
//  }
//
//  func deleteSelection() {
//    if let id = manager.selectedToDo?.id {
//      manager.delete(todoID: id)
//    }
//  }
//
//  func createToDo() {
//    let id = manager.createToDo()
//    focusProposer.send(proposal: .todos(.todo(id: id)))
//  }
//
//  @PublishedModel private var manager: ToDoManager
// }
