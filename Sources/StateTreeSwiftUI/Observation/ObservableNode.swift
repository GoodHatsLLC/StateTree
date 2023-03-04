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

  func start(didStop: @escaping () -> Void) -> AnyDisposable {
    scope
      .runtime
      .updateEmitter
      .compactMap { [id = scope.nid] change in
        switch change {
        case .started(let updatedID) where updatedID == id:
          return ChangeEvent.update
        case .updated(let updatedID) where updatedID == id:
          return ChangeEvent.update
        case .stopped(let stoppedID) where stoppedID == id:
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
          didStop()
        }
      }
  }

  // MARK: Private

  private var disposable: AnyDisposable?

}
