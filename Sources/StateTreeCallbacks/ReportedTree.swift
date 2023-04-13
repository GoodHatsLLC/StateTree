import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTree
import SwiftUI
import Utilities

// MARK: - ReportedTree

@TreeActor
public final class ReportedTree<N: Node> {

  // MARK: Lifecycle

  public init(tree: Tree<N>) {
    self.tree = tree
  }

  // MARK: Public

  public var root: Reported<N> {
    get throws {
      try Reported(tree.assume.root)
    }
  }

  // MARK: Private

  private let tree: Tree<N>

  private let subject = ValueSubject<Reported<N>?, Never>(nil)

}

// MARK: - TreeAlreadyStartedError

public struct TreeAlreadyStartedError: Error { }

// MARK: - TreeLifetimeCancelledError

public struct TreeLifetimeCancelledError: Error { }
