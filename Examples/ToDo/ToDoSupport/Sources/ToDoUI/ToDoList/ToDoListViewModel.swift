// import Combine
// import StateTree
// import StateTreeSwiftUI
// import SwiftUI
// import ToDoDomain
//
//// protocol ToDoListSource {
////    var filter: SearchFilter { get set }
////    func createToDo() -> UUID
////    func delete(todoID: UUID)
//// }
//// extension ToDoManager: ToDoListSource {}
//
// final class ToDoListViewModel: ObservableObject {
//
//  init(
//    model: ToDoList,
//    manager: ToDoManager,
//    focusProposer: FocusProposer
//  ) {
//    self.model = model
//    self.manager = manager
//    self.focusProposer = focusProposer
//  }
//
//  let focusProposer: FocusProposer
//
//  var filter: SearchFilter {
//    get { manager.filter }
//    set { manager.filter = newValue }
//  }
//
//  var todos: [ToDoData] {
//    get { model.todos }
//    set { model.todos = newValue }
//  }
//
//  var resultsAreEmpty: Bool {
//    model.todos.isEmpty
//  }
//
//  /// The selected ToDo's ID if it is available in the search results
//  var selectedToDoID: UUID? {
//    // Guard against telling SwiftUI to show something it can't.
//    if let underlying = model.selectedToDoID,
//      resultsContain(id: underlying)
//    {
//      return underlying
//    } else {
//      return nil
//    }
//  }
//
//  /// Report UI layer selection. It may be invalidated in updates.
//  func proposeToDoSelection(id: UUID) {
//    if resultsContain(id: id) {
//      model.selectedToDoID = id
//    } else {
//      model.selectedToDoID = nil
//    }
//  }
//
//  func clearFilters() {
//    manager.filter = SearchFilter(type: .all)
//  }
//
//  func createToDo() {
//    let id = manager.createToDo()
//    focusProposer.send(proposal: .todos(.todo(id: id)))
//  }
//
//  func checkmarkImageName(isCompleted: Bool) -> String {
//    isCompleted ? "checkmark.square.fill" : "square"
//  }
//
//  func foregroundColor(todoID: UUID) -> Color {
//    model.selectedToDoID == todoID ? .primary : .accentColor
//  }
//
//  func toggleIsCompleted(todoID: UUID) {
//    model.toggleIsCompleted(todoID: todoID)
//  }
//
//  func delete(todoID: UUID) {
//    manager.delete(todoID: todoID)
//  }
//
//  @PublishedModel private var model: ToDoList
//  @PublishedModel private var manager: ToDoManager
//
//  private func resultsContain(id: UUID) -> Bool {
//    model.todos.contains(where: { $0.id == id })
//  }
//
// }
