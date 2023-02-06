#if !CUSTOM_ACTOR
import Combine
import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTree
import SwiftUI

// MARK: - RootNodeObject

@MainActor
public final class RootNodeObject<N: Node>: ObservableObject {

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
      .filter { [id = life.root.id] in $0 == id }
      .subscribe { [weak self] _ in
        self?.objectWillChange.send()
      }
  }

  // MARK: Private

  private var disposable: AnyDisposable?

}
#endif
