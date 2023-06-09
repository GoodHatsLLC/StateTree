import Foundation
import OrderedCollections
import StateTree
import UIComponents

public struct TagEditor: Node {

  // MARK: Lifecycle

  init(
    selected: Projection<UUID?>,
    allTags: Projection<OrderedDictionary<UUID, TagRecord>>,
    isActive: Projection<Bool>
  ) {
    _selected = selected
    _initialSelected = .init(wrappedValue: selected.value)
    _allTags = allTags
    _isActive = isActive
    if let selected = selected.value, let tag = allTags[selected]?.compact()?.value {
      _editingTag = .init(wrappedValue: tag)
    } else {
      _editingTag = .init(wrappedValue: .init(id: UUID()))
    }
  }

  // MARK: Public

  public enum Failure: Error {
    case databaseError(any Error)
    case idCreationError
  }

  @Value public var editingTag: TagRecord

  public var rules: some Rules {
    OnUpdate(selected) { new in
      if new != initialSelected {
        isActive = false
      }
    }
  }

  public func dismiss() {
    isActive = false
  }

  public func deleteTag() {
    guard
      let existing = allTags[editingTag.id]
    else {
      isActive = false
      return
    }
    scope.run {
      let tagID = existing.id
      allTags[tagID] = nil
      isActive = false
    }
  }

  public func saveTag() {
    guard !editingTag.name.isEmpty
    else {
      return
    }
    scope.run {
      let id = selected ?? UUID()
      allTags[id] = .init(id: id, name: editingTag.name, colour: editingTag.colour)
      isActive = false
    }
  }

  // MARK: Internal

  @Projection var selected: UUID?
  @Value var initialSelected: UUID?
  @Projection var allTags: OrderedDictionary<UUID, TagRecord>
  @Projection var isActive: Bool

  // MARK: Private

  @Scope private var scope
}
