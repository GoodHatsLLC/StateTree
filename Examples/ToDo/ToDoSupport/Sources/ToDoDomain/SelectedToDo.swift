import Foundation
import StateTree

// MARK: - SelectedToDo

/// A model representing a single editable ToDo.
///
/// This model represents state projected out of
/// the ToDoManager.
/// Changes made by this model are automatically
/// pushed back into the State in the ToDoManager.
public struct SelectedToDo: Model {

  public init(
    store: Store<Self>
  ) {
    self.store = store

    // Expose the properties of a ToDo that we want
    // to allow the UI layer to show to users.
    _tags = store.proxy(\.todo.tagData.tags)
    _isCompleted = store.proxy(\.todo.completionData.isCompleted)
    _dueDate = store.proxy(\.todo.dueDate.date)
    _note = store.proxy(\.todo.noteData.note)
    _title = store.proxy(\.todo.titleData.title)
  }

  public struct State: ModelState {
    var todo: ToDoData = .init()
  }

  public let store: Store<Self>

  @StoreValue public var tags: [Tag]
  @StoreValue public var isCompleted: Bool
  @StoreValue public var dueDate: Date?
  @StoreValue public var note: String?
  @StoreValue public var title: String?

  public var id: UUID { store.read.todo.id }

  /// Find tags on a ToDo that lack a title.
  public func emptyTags() -> [UUID] {
    tags.filter { $0.title == "" }
      .map { $0.id }
  }

  /// Add an (empty) tag to a ToDo.
  public func addTag() -> UUID {
    let tag = Tag(title: "")
    tags += [tag]
    return tag.id
  }

  /// This model does not have submodels and so
  /// does not need a `route(state:)` implementation.
  @RouteBuilder
  public func route(state _: Projection<State>) -> some Routing {}
}

extension SelectedToDo.State {

  /// Provide some default state for SwiftUI previews to use.
  public static var previewState: Self {
    .init(
      todo: ToDoData(
        id: .init(),
        completionData: .init(),
        titleData: .init(title: "A title"),
        noteData: .init(),
        tagData: .init()
      )
    )
  }
}
