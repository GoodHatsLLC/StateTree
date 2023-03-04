import Foundation
import StateTree

// MARK: - ToDoSearch

public struct ToDoSearch: Node {
  @Projection var toDoData: [UUID: ToDoData]
  @Projection var tagData: [UUID: TagData]
  @Projection var filteredToDos: [ToDoData]
  @Value var filter: SearchFilter?

  private func runFilter() {
    if let filter {
      filteredToDos = toDoData
        .values
        .map { todo in (todo, todo.tagIDs.compactMap { tagData[$0] }) }
        .filter { todo, tags in
          filter.matches(todo: todo, tags: tags)
        }
        .map(\.0)
    } else {
      filteredToDos = Array(toDoData.values)
    }
  }

  public var rules: some Rules {
    OnChange(filter) {
      _ in runFilter()
    }
  }
}
