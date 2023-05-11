import Foundation
import StateTree

// MARK: - ToDo

public struct ListedToDo: Node, Identifiable {

  // MARK: Public

  public var id: UUID {
    record.id
  }

  public var title: String {
    get { record.title }
    set { record.title = newValue }
  }

  public var isCompleted: Bool {
    get { record.completed }
    set { record.completed = newValue }
  }

  public var dueDate: Date? {
    get { record.dueDate }
    set { record.dueDate = newValue }
  }

  public var rules: some Rules {
    ()
  }

  // MARK: Internal

  @Projection var record: ToDoRecord

  // MARK: Private

  @Scope private var scope

}
