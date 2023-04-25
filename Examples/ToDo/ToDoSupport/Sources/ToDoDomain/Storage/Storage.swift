import Foundation
import TreeState

// MARK: - PersistentStorage

struct PersistentStorage {
  func listToDos(range: Range<UInt>) async throws -> [UUID] { try await listToDosFunc(range) }
  func get(todo id: UUID) async throws -> ToDoData? { try await getTodoFunc(id) }
  func set(todo id: UUID, to data: ToDoData) async throws { try await setTodoFunc(id, data) }
  func get(tag id: UUID) async throws -> TagData? { try await getTagFunc(id) }
  func set(tag id: UUID, to data: TagData) async throws { try await setTagFunc(id, data) }

  private let listToDosFunc: (Range<UInt>) async throws -> [UUID]
  private let getTodoFunc: (UUID) async throws -> ToDoData?
  private let setTodoFunc: (UUID, ToDoData) async throws -> Void
  private let getTagFunc: (UUID) async throws -> TagData?
  private let setTagFunc: (UUID, TagData) async throws -> Void
}

// MARK: - WriteFailure

struct WriteFailure: Error { }

// MARK: - ReadFailure

struct ReadFailure: Error { }
