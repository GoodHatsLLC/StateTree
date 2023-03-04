// import Combine
// import Foundation
// import StateTree
// import StateTreeSwiftUI
// import ToDoDomain
//
// public final class MenuViewModel: ObservableObject {
//  public init(
//    manager: ToDoManager,
//    focusProposer: FocusProposer
//  ) {
//    self.manager = manager
//    self.focusProposer = focusProposer
//  }
//
//  var hasSelection: Bool {
//    manager.selectedToDo?.id != nil
//  }
//
//  func addTag() {
//    if let empty = manager.selectedToDo?.emptyTags().first {
//      focusProposer.send(proposal: .selected(.tag(id: empty)))
//    } else if let id = manager.selectedToDo?.addTag() {
//      focusProposer.send(proposal: .selected(.tag(id: id)))
//    }
//  }
//
//  func deleteSelection() {
//    if let id = manager.selectedToDo?.id {
//      manager.delete(todoID: id)
//      focusProposer.send(proposal: .todos(.any))
//    }
//  }
//
//  func createToDo() {
//    _ = manager.createToDo()
//  }
//
//  func toggleCompletion() {
//    if let id = manager.selectedToDo?.id {
//      manager.toggleCompletion(id: id)
//      focusProposer.send(proposal: .selected(.completion))
//    }
//  }
//
//  func resetFilters() {
//    focusProposer.send(proposal: .filters(.specific(.all)))
//  }
//
//  func focusFilters() {
//    focusProposer.send(proposal: .filters(.any))
//  }
//
//  func focusFind() {
//    focusProposer.send(proposal: .todos(.find))
//  }
//
//  func focusList() {
//    focusProposer.send(proposal: .todos(.any))
//  }
//
//  func editNote() {
//    focusProposer.send(proposal: .selected(.note))
//  }
//
//  func editTitle() {
//    focusProposer.send(proposal: .selected(.title))
//  }
//
//  func editDate() {
//    focusProposer.send(proposal: .selected(.date))
//  }
//
//  func clearDate() {
//    manager.selectedToDo?.dueDate = nil
//    focusProposer.send(proposal: .selected(.date))
//  }
//
//  private let focusProposer: FocusProposer
//
//  @PublishedModel private var manager: ToDoManager
//
// }
