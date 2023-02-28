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

  let scope: NodeScope<N>

  func start() -> AnyDisposable {
    scope
      .runtime
      .updateEmitter
      .filter { [id = scope.id] in $0 == id }
      .subscribe { [weak self] _ in
        self?.objectWillChange.send()
      }
  }

  // MARK: Private

  private var disposable: AnyDisposable?

}
