import Combine
import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTree
import SwiftUI

// MARK: - ObservableNode

@MainActor
final class ObservableNode<N: Node>: ObservableObject {

  // MARK: Lifecycle

  init(scope: NodeScope<N>) {
    self.scope = scope
  }

  // MARK: Internal

  enum ChangeEvent {
    case update
    case stop
  }

  let scope: NodeScope<N>

  func startIfNeeded() {
    disposable = disposable ?? scope
      .runtime
      .updateEmitter
      .compactMap(\.maybeNode)
      .compactMap { [id = scope.nid] change in
        switch change {
        case .start(let updatedID, _) where updatedID == id:
          return ChangeEvent.update
        case .update(let updatedID, _) where updatedID == id:
          return ChangeEvent.update
        case .stop(let stoppedID, _) where stoppedID == id:
          return ChangeEvent.stop
        case _:
          return nil
        }
      }
      .subscribe { [weak self] change in
        switch change {
        case .update:
          self?.objectWillChange.send()
        case .stop:
          self?.disposable?.dispose()
          self?.disposable = nil
        }
      }
  }

  // MARK: Private

  private var disposable: AutoDisposable?

}
