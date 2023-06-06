@_spi(Implementation) import StateTreeBase
@_spi(Implementation) import Disposable
import StateTreePlayback
import SwiftUI

// MARK: - PreviewNode

@MainActor
@propertyWrapper
public struct PreviewNode<N: Node> {

  // MARK: Lifecycle

  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    wrappedValue: N
  ) {
    self.wrappedValue = wrappedValue
    self.moduleFile = moduleFile
    self.line = line
    self.column = column
  }

  // MARK: Public

  public let wrappedValue: N

  public var projectedValue: TreeNode<N> {
    PreviewLifetime(root: wrappedValue)
      .node(
        moduleFile: moduleFile,
        line: line,
        column: column,
        node: wrappedValue
      )
  }

  // MARK: Private

  private let moduleFile: String
  private let line: Int
  private let column: Int

}

// MARK: - PreviewLifetime

@MainActor
public struct PreviewLifetime<N: Node> {
  init(
    root: N
  ) {
    self.root = root
  }

  public func node(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    node _: N
  ) -> TreeNode<N> {
    let tree = try! Tree(root: root)
      .start()
    tree
      .autostop()
      .stageByUniqueCallSite(location: (fileID: moduleFile, line: line, column: column))

    return TreeNode(scope: tree.root)
  }

  private let root: N
}
