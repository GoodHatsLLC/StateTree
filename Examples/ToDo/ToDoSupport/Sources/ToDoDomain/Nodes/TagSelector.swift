import Foundation
import OrderedCollections
import StateTree
import UIComponents

public struct TagSelector: Node {

  // MARK: Public

  public struct TagInfo: Hashable, Identifiable, Comparable {
    init?(record: TagRecord, isSelected: Bool) {
      self.id = record.id
      self.record = record
      self.isSelected = isSelected
    }

    public static func < (lhs: TagSelector.TagInfo, rhs: TagSelector.TagInfo) -> Bool {
      lhs.name < rhs.name
    }

    public let id: UUID
    public var name: String { record.name }
    public var colour: Colour { record.colour }
    public let isSelected: Bool
    let record: TagRecord
  }

  @Value public var searchText: String = ""

  public var matchingTags: [TagRecord] {
    allTags
      .filter { record in
        searchText == "" || record.value.name.hasPrefix(searchText)
      }
      .values
      .elements
  }

  public var selectedMatchingTags: Set<UUID> {
    get { Set(matchingTags.map(\.id).filter { todo.tags.contains($0) }) }
    set {
      let last = selectedMatchingTags
      let removed = last.subtracting(newValue)
      let added = newValue.subtracting(last)
      todo.tags.subtract(removed)
      todo.tags.formUnion(added)
    }
  }

  public var rules: some Rules {
    ()
  }

  public func addTag(_ tag: TagInfo) {
    todo.tags.insert(tag.id)
  }

  public func removeTag(_ tag: TagInfo) {
    todo.tags.remove(tag.id)
  }

  // MARK: Internal

  @Projection var allTags: OrderedDictionary<UUID, TagRecord>
  @Projection var todo: ToDoRecord

  // MARK: Private

  @Scope private var scope
}
