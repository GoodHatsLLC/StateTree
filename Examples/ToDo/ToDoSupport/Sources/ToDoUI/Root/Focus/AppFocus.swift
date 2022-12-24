import Combine
import Foundation
import ToDoDomain

public enum AppFocus: Hashable {

  case unfocussed
  case filters(FilterFocus)
  case todos(ToDoListFocus)
  case selected(SelectedFocus)

  public enum FilterFocus: Hashable {
    case specific(ToDoMetadata)
    case any
  }

  public enum NavigationFocus: Hashable {
    case filters
    case todos
    case selected
  }

  public enum SelectedFocus: Hashable {
    case tag(id: UUID)
    case title
    case note
    case date
    case completion

    var tagID: UUID? {
      switch self {
      case .tag(let id): return id
      case .title: return nil
      case .note: return nil
      case .date: return nil
      case .completion: return nil
      }
    }

  }

  public enum ToDoListFocus: Hashable {
    case any
    case find
    case todo(id: UUID)

    var todoID: UUID? {
      switch self {
      case .todo(let id): return id
      case .any: return nil
      case .find: return nil
      }
    }
  }

  var navigation: NavigationFocus? {
    switch self {
    case .unfocussed: return nil
    case .filters: return .filters
    case .selected: return .selected
    case .todos: return .todos
    }
  }

}
