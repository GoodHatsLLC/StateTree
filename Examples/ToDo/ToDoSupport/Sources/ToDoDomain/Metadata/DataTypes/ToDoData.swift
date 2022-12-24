import Foundation
import StateTree

// MARK: - ToDoData

public struct ToDoData: ModelState, Identifiable {
  public var id: UUID = .init()
  public var completionData: CompletionData = .init()
  public var titleData: TitleData = .init()
  public var noteData: NoteData = .init()
  public var tagData: TagData = .init()
  public var dueDate: DueDateData = .init()
}
