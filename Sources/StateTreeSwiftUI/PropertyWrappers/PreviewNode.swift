#if !CUSTOM_ACTOR
@_spi(Implementation) import StateTree
import SwiftUI
import TimeTravel

@MainActor
@propertyWrapper
public struct PreviewNode<N: Node> {

  // MARK: Lifecycle

  public init(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    wrappedValue: N
  ) {
    self.wrappedValue = wrappedValue
    self.fileID = fileID
    self.line = line
    self.column = column
  }

  // MARK: Public

  public let wrappedValue: N

  public var projectedValue: TreeNode<N> {
    PreviewLife(root: wrappedValue)
      .node(
        fileID: fileID,
        line: line,
        column: column
      )
  }

  // MARK: Private

  private let fileID: String
  private let line: Int
  private let column: Int

}

@MainActor
public struct PreviewLife<N: Node> {
  init(
    root: N
  ) {
    self.root = root
  }

  public func node(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    tree: Tree = Tree(),
    record: TreeStateRecord? = nil,
    dependencies: DependencyValues = .defaults
  ) -> TreeNode<N> {
    let life = try! tree
      .start(
        root: root,
        from: record,
        dependencies: dependencies,
        configuration: .init()
      )
    life.stageOneByLocation(fileID: fileID, line: line, column: column)
    return TreeNode(scope: life.root)
  }

  private let root: N
}

#endif
