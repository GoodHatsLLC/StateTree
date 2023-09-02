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
    // always serve the list of todos.
    $todoList.serve(data: $records.values, identifiedBy: \.id) { datum in
      ListedToDo(record: datum)
    }

    // if we can get a projection of the selected record, serve it
    // as the selected todo node.
    if
      let uuid = selectedRecord,
      let maybeRecordProjection = $records[uuid],
      let selected = Projection(maybeRecordProjection)
    {
      $selectedToDo.serve {
        SelectedToDo(
          record: selected,
          allTags: $allTags
        )
      }
    }

    // show the tag editor only if desired.
    if showTagEditor {
      $tagEditor.serve {
        TagEditor(
          selected: $selectedTag,
          allTags: $allTags,
          isActive: $showTagEditor
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
      showTagEditor = true
    }
  }

  public func editTag(id tagID: UUID) {
    scope.transaction {
      selectedTag = tagID
      showTagEditor = true
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
  @Value private var showTagEditor: Bool = false

  private func getToDo(id: UUID) -> ToDoRecord? {
    return records[id]
  }

}
