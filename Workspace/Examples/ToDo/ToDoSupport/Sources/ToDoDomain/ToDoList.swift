import Foundation
import StateTree

// MARK: - ToDoList

public struct ToDoList: Node {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  @Route([ToDo].self) public var filteredToDos
  @Route(ToDo.self) public var selectedToDo
  @Route(ToDoSearch.self) public var search

  public var rules: some Rules {
    $loader.route(
      to: ToDoLoader(toDoData: $toDoData)
    )
    $search.route(
      to: ToDoSearch(
        toDoData: $toDoData,
        tagData: $tagData,
        filteredToDos: $filteredToDoData
      )
    )
    $filteredToDos.route {
      var todos: [ToDo] = []
      for projection in $filteredToDoData {
        todos.append(
          ToDo(
            id: projection.value.id,
            tagIDs: projection.tagIDs,
            isCompleted: projection.isCompleted,
            dueDate: projection.dueDate,
            note: projection.note,
            title: projection.title,
            selectedToDoID: $selected
          )
        )
      }
      return todos
    }
    if
      let selected,
      let data = $toDoData[selected].compact()
    {
      $selectedToDo.route(
        to: ToDo(
          id: selected,
          tagIDs: data.tagIDs,
          isCompleted: data.isCompleted,
          dueDate: data.dueDate,
          note: data.note,
          title: data.title,
          selectedToDoID: $selected
        )
      )
    }
  }

  // MARK: Private

  @Value private var toDoData: [UUID: ToDoData] = [:]
  @Value private var filteredToDoData: [ToDoData] = []
  @Value private var tagData: [UUID: TagData] = [:]
  @Value private var selected: UUID?
  @Route(ToDoLoader.self) private var loader
}
