import Foundation
import StateTree

public struct TitleData: ModelState, Metadata {
  public var title: String?

  public var type: ToDoMetadata { .title }

  func matches(query: SearchQuery) -> Bool {
    switch query {
    case .none:
      return true
    case .toggle:
      return false
    case .date:
      return false
    case .text(let text):
      return title?
        .lowercased()
        .contains(
          text.lowercased()
        ) ?? false
    }
  }

}
