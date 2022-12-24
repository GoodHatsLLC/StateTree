import Foundation
import StateTree

// MARK: - SearchFilter

public struct SearchFilter: ModelState {
  public init(type: ToDoMetadata) {
    query = type.initialQuery
    self.type = type
  }

  public var isEmpty: Bool {
    query == type.initialQuery
  }

  public var query: SearchQuery
  public var type: ToDoMetadata
}

// MARK: - SearchQuery

public enum SearchQuery: ModelState {
  case none
  case text(String)
  case toggle(Bool)
  case date(Date)

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

public enum ToDoMetadata: ModelState, CaseIterable, Identifiable {
  case all
  case title
  case completed
  case note
  case tags
  case dueDate

  public var id: String {
    text
  }

  public var text: String {
    switch self {
    case .all: return "All"
    case .title: return "Title"
    case .completed: return "Completed"
    case .note: return "Notes"
    case .tags: return "Tags"
    case .dueDate: return "Due Date"
    }
  }

  public var shortText: String {
    switch self {
    case .all: return "All"
    case .title: return "Title"
    case .completed: return "Complete"
    case .note: return "Notes"
    case .tags: return "Tags"
    case .dueDate: return "Due"
    }
  }

  public var initialQuery: SearchQuery {
    switch self {
    case .all:
      return .none
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

  func matches(_ todo: ToDoData, query: SearchFilter?) -> Bool {
    guard let query
    else {
      return true
    }
    switch query.query {
    case .text(""),
      .none:
      return true
    default: break
    }
    if query.type == .all {
      return
        todo
        .metadata
        .filter { $0.matches(query: query.query) }
        .count > 0
    } else {
      return
        todo
        .metadata
        .filter { $0.type == query.type }
        .filter { $0.matches(query: query.query) }
        .count > 0
    }
  }
}

// MARK: - Metadata

protocol Metadata {
  var type: ToDoMetadata { get }
  func matches(query: SearchQuery) -> Bool
}

extension ToDoData {
  var metadata: [any Metadata] {
    [
      completionData,
      titleData,
      noteData,
      tagData,
      dueDate,
    ]
  }
}
