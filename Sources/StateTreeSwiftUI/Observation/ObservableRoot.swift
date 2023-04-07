import Combine
import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTree
import SwiftUI

// MARK: - ObservableRoot

@MainActor
public final class ObservableRoot<N: Node>: ObservableObject {

  // MARK: Lifecycle

  init(tree: Tree_REMOVE = .main, root: N) throws {
    self.life = try tree.start(root: root)
  }

  // MARK: Internal

  let life: Tree<N>

}
