import Combine
import Foundation
import StateTree
import StateTreeSwiftUI
import ToDoDomain

final class FilterListViewModel: ObservableObject {
  init(
    manager: ToDoManager,
    focusProposer: FocusProposer
  ) {
    self.manager = manager
    self.focusProposer = focusProposer
  }

  let focusProposer: FocusProposer

  var filterType: ToDoMetadata {
    get { manager.filter.type }
    set { manager.filter = SearchFilter(type: newValue) }
  }

  @PublishedModel private var manager: ToDoManager
}
