import Foundation
import StateTree

public struct NoteData: ModelState, Metadata {
  public var note: String?

  public var type: ToDoMetadata { .note }

  func matches(query: SearchQuery) -> Bool {
    switch query {
    case .none:
      return true
    case .toggle:
      return false
    case .date:
      return false
    case .text(let text):
      return note?.lowercased()
        .contains(
          text.lowercased()
        ) ?? false
    }
  }
}
