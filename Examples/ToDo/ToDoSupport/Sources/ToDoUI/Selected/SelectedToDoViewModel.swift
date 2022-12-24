import Combine
import StateTree
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain

/// A SwiftUI ObservableObject exposing values
/// from a SelectedToDo domain model to the SwiftUI
/// View layer.
///
/// The view model layer also handles SwiftUI focus
/// functionality — as it is UI state that is not
/// modelled in the StateTree domain models.
final class SelectedToDoViewModel: ObservableObject {

  init(
    model: SelectedToDo,
    focusProposer: FocusProposer
  ) {
    self.model = model
    self.focusProposer = focusProposer
  }

  /// `@PublishedModel` functions like `@Published`
  /// and notifies SwiftUI to update based on its changes.
  @PublishedModel var model: SelectedToDo

  let focusProposer: FocusProposer

  var id: UUID { model.id }

  /// Computedd view model fields derived from the
  /// @PublishedModel domain model are not directly
  /// marked as influencing SwiftUI.
  ///
  /// The underlying changes in the @PublishedModel
  /// will already prompt SwiftUI to rerender.
  var note: String {
    get { model.note ?? "" }
    set { model.note = newValue.isEmpty ? nil : newValue }
  }

  var tags: [Tag] {
    get { model.tags }
    set { model.tags = newValue }
  }

  var title: String {
    get { model.title ?? "" }
    set { model.title = newValue.isEmpty ? nil : newValue }
  }

  var isCompleted: Bool {
    get { model.isCompleted }
    set { model.isCompleted = newValue }
  }

  var dateOpacity: Double {
    model.dueDate != nil ? 1 : 0.6
  }

  /// A binding into the underlying Store
  /// data — that is modified in its projection
  /// to allow it to be more easily consumed.
  var dateBinding: Binding<Date> {
    model
      .projection
      .dueDate
      .replaceNil(default: .now)
      .binding()
  }

  var canMakeNewTag: Bool {
    model.tags.first(where: { $0.title.isEmpty }) == nil
  }

  func clearEmptyTagFields() {
    model.tags.removeAll { tag in
      tag.title.isEmpty
    }
  }

  func clearDate() {
    model.dueDate = nil
  }

  func newTag() {
    let id = model.addTag()
    focusProposer.send(proposal: .selected(.tag(id: id)))
  }

}
