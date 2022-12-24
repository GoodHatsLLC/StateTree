import Combine
import Disposable
import Emitter
import Foundation
import Model
import SwiftUI
import Tree

// MARK: - ObservableTree

@MainActor
public final class ObservableTree<Root: Model>: ObservableObject {

  public init(_ tree: Tree<Root>) {
    self.tree = tree
    tree
      .didStart
      .subscribe { [weak self] in
        self?.objectWillChange.send()
      }
      .stage(on: stage)
  }

  public var tree: Tree<Root>

  public var root: Root {
    tree.rootModel
  }

  private var stage = DisposalStage()
}

extension ObservableTree {
  public func start(
    options: [StartOption] = []
  ) throws
    -> AnyDisposable
  {
    try tree.start(options: options)
  }
}

extension Tree {
  public typealias Observable = ObservableTree<Root>

  public func asObservable() -> ObservableTree<Root> {
    .init(self)
  }

}
