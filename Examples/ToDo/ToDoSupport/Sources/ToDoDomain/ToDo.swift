import Foundation
import StateTree

// MARK: - UnknownToDoRecord

struct UnknownToDoRecord: Error { }

// MARK: - ToDo

public struct ToDo: Node, Identifiable {

  // MARK: Lifecycle

  init(record dbRecord: ToDoRecord) throws {
    _record = .init(wrappedValue: dbRecord)
    _isPersisted = .init(wrappedValue: true)
    if dbRecord.id == nil {
      throw UnknownToDoRecord()
    }
  }

  init() async throws {
    var record = ToDoRecord.new()
    try await db.saveToDo(&record)
    _record = .init(wrappedValue: record)
    _isPersisted = .init(wrappedValue: true)
  }

  // MARK: Public

  public var id: Int64 {
    record!.id!
  }

  public var title: String {
    get {
      record?.title ?? ""
    }
    set {
      record?.title = newValue
    }
  }

  public var isCompleted: Bool {
    get { record?.completed ?? false }
    set { record?.completed = newValue }
  }

  public var dueDate: Date? {
    get { record?.dueDate }
    set { record?.dueDate = newValue }
  }

  public var rules: some Rules {
    ()
  }

  public func save() {
    scope.run {
      var record = record!
      try await db.saveToDo(&record)
      self.record = record
    }
  }

  // MARK: Private

  @Dependency(\.database) private var db
  @Value private var record: ToDoRecord?
  @Value private var isPersisted: Bool = false
  @Scope private var scope

}
