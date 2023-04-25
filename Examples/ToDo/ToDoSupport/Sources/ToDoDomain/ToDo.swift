import Foundation
import StateTree

// MARK: - SelectedToDo

public struct ToDo: Node, Identifiable {

  public let id: UUID
  @Scope private var scope
  @Route([Tag].self) public var tags
  @Projection public var tagIDs: [UUID]
  @Projection public var isCompleted: Bool
  @Projection public var dueDate: Date?
  @Projection public var note: String?
  @Projection public var title: String?

  @Projection var selectedToDoID: UUID?

  public var isSelected: Bool {
    get {
      selectedToDoID == id
    }
    set {
      selectedToDoID = newValue ? id : nil
    }
  }

  public var rules: some Rules {
    $tags.route {
      tagIDs.map { id in
        Tag(id: id)
      }
    }
  }

}

//
// extension ToDo {
//
//  /// Provide some default state for SwiftUI previews to use.
//  public static var example: Self {
//    .init(
//      TODO: ToDoData(
//        id: .init(),
//        completionData: .init(),
//        titleData: .init(title: "A title"),
//        noteData: .init(),
//        tagData: .init()
//      )
//    )
//  }
// }
