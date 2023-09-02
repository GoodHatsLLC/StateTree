import Foundation
import UIComponents

// MARK: - ToDoRecord

public struct ToDoRecord: Identifiable, Codable, Hashable {
  public init(
    id: UUID,
    title: String = "",
    note: String = "",
    dueDate: Date? = nil,
    completed: Bool = false,
    tags: Set<UUID> = []
  ) {
    self.id = id
    self.title = title
    self.note = note
    self.dueDate = dueDate
    self.completed = completed
    self.tags = tags
  }

  public private(set) var id: UUID
  public var title: String = ""
  public var note: String = ""
  public var dueDate: Date?
  public var completed: Bool = false
  public var tags: Set<UUID> = []
}

// MARK: - TagRecord

public struct TagRecord: Identifiable, Codable, Hashable {
  public var id: UUID
  public var name: String = ""
  public var colour: Colour = Self.randomColour

  static var randomColour: Colour {
    [Colour.red, .blue, .yellow, .cyan, .green, .orange, .purple]
      .randomElement() ?? .red
  }
}
