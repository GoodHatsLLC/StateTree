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

  enum ChangeEvent {
    case update
    case stop
  }

  let life: TreeLifetime<N>

  func start() -> AnyDisposable {
    life
      .runtime
      .updateEmitter
      .compactMap { [id = life.rootID] change in
        switch change {
        case .updated(let updatedID) where updatedID == id:
          return ChangeEvent.update
        case .stopped(let stoppedID) where stoppedID == id:
          return ChangeEvent.stop
        case _:
          return nil
        }
      }
      .subscribe { change in
        switch change {
        case .update:
          self.objectWillChange.send()
        case .stop:
          self.disposable?.dispose()
        }
      }
  }

  // MARK: Private

  private var disposable: AnyDisposable?

}
