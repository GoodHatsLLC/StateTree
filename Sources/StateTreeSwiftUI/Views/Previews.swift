import Dependencies
import Emitter
import Foundation
import Model
import Node
import Tree
import Utilities

extension Model {
  @MainActor
  public static func preview<T: Model>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    state: T.State,
    builder: (_ store: Store<T>) -> T
  )
    -> T
  {
    let tree: Tree<T> = .init(rootModelState: state, hooks: TreeHooks(), builder: builder)
    do {
      try tree.start()
        .stageOne(
          by: (
            fileID: fileID,
            line: line,
            column: column
          )
        )
    } catch {
      DependencyValues.defaults.logger.log(
        "💥",
        message: "Preview failed starting: \(Self.self)",
        error.localizedDescription
      )
    }
    return tree.rootModel
  }
}

extension ObservableObject {
  @MainActor
  public static func preview<T: Model, O: ObservableObject>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    state: T.State,
    model modelBuilder: (_ store: Store<T>) -> T,
    viewModel viewModelBuilder: (_ model: T) -> O
  )
    -> O
  {
    viewModelBuilder(
      T.preview(
        fileID: fileID,
        line: line,
        column: column,
        state: state,
        builder: modelBuilder
      )
    )
  }
}
