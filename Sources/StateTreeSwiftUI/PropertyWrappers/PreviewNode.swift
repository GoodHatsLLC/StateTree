@_spi(Implementation) import StateTree
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
    fatalError()
//    PreviewLife(root: wrappedValue)
//      .node(
//        moduleFile: moduleFile,
//        line: line,
//        column: column
//      )
  }

  // MARK: Private

  private let moduleFile: String
  private let line: Int
  private let column: Int

}

// MARK: - PreviewLife

@MainActor
public struct PreviewLife<N: Node> {
  init(
    root: N
  ) {
    self.root = root
  }

  public func node(
    moduleFile _: String = #file,
    line _: Int = #line,
    column _: Int = #column,
    _: N,
    record _: TreeStateRecord? = nil,
    dependencies _: DependencyValues = .defaults
  ) -> TreeNode<N> {
    fatalError()
//    let life = try! tree
//      .start(
//        root: root,
//        from: record,
//        dependencies: dependencies,
//        configuration: .init()
//      )
//    life.stageByUniqueCallSite(fileID: moduleFile, line: line, column: column)
//    return TreeNode(scope: life.root)
  }

  private let root: N
}
