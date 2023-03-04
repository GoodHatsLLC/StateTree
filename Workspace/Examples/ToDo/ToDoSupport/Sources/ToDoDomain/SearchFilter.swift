import Foundation
import StateTree

// MARK: - SearchFilter

public struct SearchFilter: TreeState {
  public init(type: ToDoMetadata) {
    self.query = type.initialQuery
    self.type = type
  }

  public var isEmpty: Bool {
    query == type.initialQuery
  }

  public var query: SearchQuery
  public var type: ToDoMetadata

  func matches(todo: ToDoData, tags: [TagData]) -> Bool {
    switch type {
    case .title:
      return todo.title?.contains(query.textQuery) ?? false
    case .completed:
      return todo.isCompleted == query.toggleQuery
    case .note:
      return todo.note?.contains(query.textQuery) ?? false
    case .tags:
      return tags.contains(where: { $0.title.contains(query.textQuery) })
    case .dueDate:
      return todo.dueDate?.timeIntervalSince(query.dateQuery).magnitude
        .isLess(than: 24 * 60 * 60) ?? false
    }
  }

}

// MARK: - SearchQuery

public enum SearchQuery: TreeState {
  case none
  case text(String)
  case toggle(Bool)
  case date(Date)

  // MARK: Public

  public var textQuery: String {
    get {
      switch self {
      case .text(let string):
        return string
      case _:
        return ""
      }
    }
    set {
      self = .text(newValue)
    }
  }

  public var toggleQuery: Bool {
    get {
      switch self {
      case .toggle(let bool):
        return bool
      case _:
        return true
      }
    }
    set {
      self = .toggle(newValue)
    }
  }

  public var dateQuery: Date {
    get {
      switch self {
      case .date(let date):
        return date
      case _:
        return .now
      }
    }
    set {
      self = .date(newValue)
    }
  }
}

// MARK: - ToDoMetadata

public enum ToDoMetadata: TreeState, CaseIterable, Identifiable {
  case title
  case completed
  case note
  case tags
  case dueDate

  // MARK: Public

  public var id: String {
    text
  }

  public var text: String {
    switch self {
    case .title: return "Title"
    case .completed: return "Completed"
    case .note: return "Notes"
    case .tags: return "Tags"
    case .dueDate: return "Due Date"
    }
  }

  public var shortText: String {
    switch self {
    case .title: return "Title"
    case .completed: return "Complete"
    case .note: return "Notes"
    case .tags: return "Tags"
    case .dueDate: return "Due"
    }
  }

  public var initialQuery: SearchQuery {
    switch self {
    case .note:
      return .text("")
    case .tags:
      return .text("")
    case .title:
      return .text("")
    case .dueDate:
      return .date(.now)
    case .completed:
      return .toggle(false)
    }
  }

}
