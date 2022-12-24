import Foundation
import StateTree

public struct CompletionData: ModelState, Metadata {
  public var isCompleted = false
  public var type: ToDoMetadata { .completed }
  func matches(query: SearchQuery) -> Bool {
    switch query {
    case .none:
      return true
    case .toggle(let bool):
      return isCompleted == bool
    case .date:
      return false
    case .text:
      return false
    }
  }
}
