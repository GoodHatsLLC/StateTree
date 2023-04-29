import GRDB
import StateTree

public struct ToDoManager: Node {

  // MARK: Lifecycle

  public init() {
    self.records = []
  }

  // MARK: Public

  @Route([ToDo].self) public var todos

  public var rules: some Rules {
    $todos.route {
      records.compactMap { record in
        try! ToDo(record: record)
      }
    }
  }

  public func reloadAll() {
    scope.run {
      let records = try await db.fetchToDos()
      self.records = records
    }
  }

  public func createToDo(title: String = "") {
    scope.run {
      var todo = ToDoRecord.new(title: title)
      try! await db.saveToDo(&todo)
      records.append(todo)
    }
  }

  // MARK: Internal

  @Scope var scope
  @Dependency(\.database) var db

  // MARK: Private

  @Value private var records: [ToDoRecord]

}
