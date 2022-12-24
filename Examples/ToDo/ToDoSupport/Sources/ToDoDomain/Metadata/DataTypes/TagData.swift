import Foundation
import StateTree

// MARK: - Tag

public struct Tag: ModelState, Identifiable {
  public init(id: UUID = UUID(), title: String) {
    self.id = id
    self.title = title
  }

  public var id = UUID()
  public var title: String
}

// MARK: - TagData

public struct TagData: ModelState, Metadata {
  public init() {}

  public var tags: [Tag] = []

  public var type: ToDoMetadata { .tags }

  func matches(query: SearchQuery) -> Bool {
    switch query {
    case .none:
      return true
    case .toggle:
      return false
    case .date:
      return false
    case .text(let text):
      return
        tags.filter { tag in
          tag.title
            .lowercased()
            .contains(text.lowercased())
        }.count > 0
    }
  }

}
