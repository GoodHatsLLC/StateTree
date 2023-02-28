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
    self.disposable = start()
  }

  // MARK: Internal

  enum ChangeEvent {
    case update
    case stop
  }

  let scope: NodeScope<N>

  func start() -> AnyDisposable {
    scope
      .runtime
      .updateEmitter
      .compactMap { [id = scope.id] change in
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
