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

  init(tree: Tree = .main, root: N) {
    self.life = try! tree.start(root: root)
  }

  // MARK: Internal

  let life: TreeLifetime<N>

  func start() -> AnyDisposable {
    life
      .runtime
      .updateEmitter
      .filter { [id = life.rootID] in $0 == id }
      .subscribe { [weak self] _ in
        self?.objectWillChange.send()
      }
  }

  // MARK: Private

  private var disposable: AnyDisposable?

}
