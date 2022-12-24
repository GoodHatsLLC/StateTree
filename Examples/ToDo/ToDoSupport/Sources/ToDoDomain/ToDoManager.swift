import Foundation
import StateTree

/// The main DomainModel in the ToDo app.
///
/// The ToDoManager is instantiated as the
/// rootModel of the @StateTree.
public struct ToDoManager: Model {

  /// A ToDoManager is a ``Model`` and so
  /// uses a ``Store`` to manage its state.
  public init(
    store: Store<Self>
  ) {
    self.store = store

    // Directly expose a value from the store.
    _filter = store.proxy(\.filter)
    _rawState = .init(projectedValue: store)
  }

  /// The state managed by the ``Store``
  /// conforms to ``ModelState``. It is
  /// `Codable`, `Hashable`, and `Sendable`.
  public struct State: ModelState {
    public init() {}
    var filter = SearchFilter(type: .all)
    var selectedToDoID: UUID?
    var todos: [ToDoData] = []
  }

  public let store: Store<Self>

  /// A @Route to a submodel listing ToDos.
  ///
  /// This property is non-nil only when the
  /// logic in the route(state:) call applies
  /// to the `State` such that it can be instantiated.
  @Route public var list: ToDoList?

  /// A @Route to a submodel available only when
  /// a ToDo is selected. (i.e. the primary ToDo
  /// to show in the UI.)
  @Route public var selectedToDo: SelectedToDo?

  /// The current `SearchFilter`.
  ///
  /// A @StoreValue is a field displayed directly
  /// from the Store (without any mapping).
  @StoreValue public var filter: SearchFilter

  /// Raw, untracked, access to the node state.
  /// (Used only for data serialisation to sqlite.)
  @RawState<Self> private var rawState: State

  /// Model Annotation which executes any time the State is updated.
  ///
  /// Used only for data serialisation to sqlite.
  @DidUpdate<Self> var didUpdate = { this in
    dump(this.rawState)
  }

  /// Create a ToDo in the store, returning
  // its UUID.
  public func createToDo() -> UUID {
    let newToDo = ToDoData(
      id: .init(),
      completionData: .init(),
      titleData: .init(),
      noteData: .init(),
      tagData: .init()
    )
    // Open a transaction to append
    // the ToDo to the list of ToDos
    // and make it the selected ToDo
    // in one single synchronous edit.
    store.transaction { state in
      state.todos += [newToDo]
      state.selectedToDoID = newToDo.id
    }
    return newToDo.id
  }

  /// Toggle the completion state for a ToDo.
  public func toggleCompletion(id: UUID) {
    store.transaction { state in
      // Find the ToDo in the list, and toggle its value.
      if let index = state.todos.firstIndex(where: { $0.id == id }) {
        state.todos[index].completionData.isCompleted.toggle()
      }
    }
  }

  /// Delete a ToDo, updating the selected
  /// ToDo to the next one in the filtered list.
  public func delete(todoID: UUID) {
    store.transaction { state in
      var todos = state.todos
      let maybeIndex: Int?

      // If there's a selected entry find its index.
      if state.selectedToDoID == todoID {
        maybeIndex = todos.firstIndex(where: { $0.id == todoID })
      } else {
        maybeIndex = nil
      }

      // Do the deletion.
      todos.removeAll { $0.id == todoID }

      // Select the next entry (now at same index)
      // unless it's off the end.
      // If off end select last if available.
      state.selectedToDoID =
        maybeIndex
        .flatMap { index in
          index < todos.endIndex ? index : nil
        }.map { index in
          todos[index].id
        } ?? todos.last?.id
      state.todos = todos
    }
  }

  /// The Routing logic determining what submodels are
  /// applicable given the current state in the ``Store``.
  @RouteBuilder
  public func route(state: Projection<State>) -> some Routing {
    // Forward the todos which match the query,
    // and any selected ToDo info to ToDoList.
    let selectionAndQueryMatching = state.todos
      .filter {
        filter
          .type
          .matches($0, query: state.filter.value)
      }
      .join(state.selectedToDoID)

    // Route into the `list` property.
    //
    // - Pass the `selectionAndQueryMatching`
    //   projection from this model's Store.
    // - Pass an initial version of the
    //   submodel's state.
    $list.route(
      selectionAndQueryMatching,
      into: ToDoList.State()
    ) { from, to in
      // define the mappings between the
      // selectionAndQueryMatching projection
      // and the submodel's state.

      // The filtered ToDo list maps
      // bidirectionally into `todos`
      from.a <-> to.todos

      // The id of the selected ToDo
      // maps bidirectionally.
      from.b <-> to.selectedToDoID
    } model: { store in
      ToDoList(store: store)
    }

    // If a ToDo is selected for editing, create a
    // model to represent it.

    // `compact()` the projected optional state
    // to get a usable optional (of a projection
    // of the non-optional state).
    //
    // This `compact()` returns nil any time no
    // ToDo is selected.
    if let id = state.selectedToDoID.compact(),
      let selected = state
        .todos
        .first(where: { $0.id == id.value })
        .compact()
    {
      // If a selected ToDo is found, route
      // into the ``SelectedToDo`` model in
      // our @Route model field.
      $selectedToDo.route(
        selected,
        into: SelectedToDo.State()
      ) { from, to in
        // the projected ToDo model maps
        // bidirectionally into the field
        // in the submodel's State.
        from <-> to.todo
      } model: { store in
        // Instantiate the submodel with
        // its Store.
        SelectedToDo(store: store)
      }
    }
  }
}
