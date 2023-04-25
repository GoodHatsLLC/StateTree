import Foundation
import TreeState

// MARK: - ToDoData

struct ToDoData: TreeState {
  let id: UUID
  var tagIDs: [UUID]
  var isCompleted: Bool
  var creationDate: Date
  var dueDate: Date?
  var note: String?
  var title: String?
}

// MARK: - TagData

struct TagData: TreeState, Comparable {
  static func < (lhs: TagData, rhs: TagData) -> Bool {
    lhs.title < rhs.title
  }

  let id: UUID
  var title: String
}
