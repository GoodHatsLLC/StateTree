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

  init(tree: Tree<N>) {
    self.life = tree
    Task {
      await tree.run()
    }
  }

  // MARK: Internal

  let life: Tree<N>

}
