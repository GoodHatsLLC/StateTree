import Foundation
import StateTree

// MARK: - ToDoList

/// A list of ToDos projected out of the ToDoManager.
///
/// The ToDos passed to this list model have been
/// filtered by logic in the ToDoManager.
///
/// Changes made to the ToDos here are automatically
/// pushed into the ToDoData values used in other models.
public struct ToDoList: Model {

  public init(
    store: Store<Self>
  ) {
    self.store = store
    _todos = store.proxy(\.todos)
    _selectedToDoID = store.proxy(\.selectedToDoID)
  }

  public struct State: ModelState {
    public init(data: [ToDoData] = []) {
      todos = data
    }

    var todos: [ToDoData] = []
    var selectedToDoID: UUID?
  }

  public let store: Store<Self>

  @StoreValue public var todos: [ToDoData]
  @StoreValue public var selectedToDoID: UUID?

  public func toggleIsCompleted(todoID: UUID) {
    store.transaction { state in
      if let index = state
        .todos
        .firstIndex(where: { $0.id == todoID })
      {
        state
          .todos[index]
          .completionData
          .isCompleted
          .toggle()
      }
    }
  }

  /// This model has no submodels and so does
  /// not need a ``route(state:)`` implementation.
  @RouteBuilder
  public func route(state _: Projection<State>) -> some Routing {}
}

extension ToDoList.State {
  /// Convenience state for SwiftUI previews
  public static var previewState: Self {
    .init(data: [
      .init(
        id: .init(),
        completionData: .init(isCompleted: true),
        titleData: .init(title: "A title"),
        noteData: .init(),
        tagData: .init()
      ),
      .init(
        id: .init(),
        completionData: .init(isCompleted: false),
        titleData: .init(title: "B title"),
        noteData: .init(),
        tagData: .init()
      ),
    ])
  }
}
