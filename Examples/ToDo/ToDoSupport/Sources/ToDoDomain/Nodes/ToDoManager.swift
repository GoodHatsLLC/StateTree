import Foundation
import OrderedCollections
import StateTree
import Utilities

// MARK: - ToDoManager

public struct ToDoManager: Node {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  @Route public var todoList: [ListedToDo] = []
  @Route public var selectedToDo: SelectedToDo? = nil
  @Route public var tagEditor: TagEditor? = nil

  @Value public var selectedRecord: UUID? = nil
  @Value public var selectedTag: UUID? = nil

  public var rules: some Rules {
    if
      let id = selectedRecord,
      let selected = $records[id].compact()
    {
      Serve(
        SelectedToDo(
          record: selected,
          allTags: $allTags
        ),
        at: $selectedToDo
      )
      Serve(data: $records.values, at: $todoList) { datum in
        ListedToDo(record: datum)
      }

      if showEditor {
        Serve(
          TagEditor(
            selected: $selectedTag,
            allTags: $allTags,
            isActive: $showEditor
          ),
          at: $tagEditor
        )
      }
    }
  }

  public var tagList: [TagRecord] {
    allTags.values.elements
  }

  public func addTag() {
    scope.transaction {
      selectedTag = nil
      showEditor = true
    }
  }

  public func editTag(id tagID: UUID) {
    scope.transaction {
      selectedTag = tagID
      showEditor = true
    }
  }

  public func createToDo() {
    scope.run {
      let todo = ToDoRecord(id: UUID())
      records[todo.id] = todo
      selectedRecord = todo.id
    }
  }

  public func deleteToDo(id: UUID) {
    $scope.run {
      records[id] = nil
    }
  }

  // MARK: Private

  @Scope private var scope

  @Value private var allTags: OrderedDictionary<UUID, TagRecord> = [:]
  @Value private var records: OrderedDictionary<UUID, ToDoRecord> = [:]
  @Value private var modifiedToDoIDs: Set<UUID> = []
  @Value private var showEditor: Bool = false

  private func getToDo(id: UUID) -> ToDoRecord? {
    return records[id]
  }

}
