import Combine
import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTreeBase
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
      .didUpdateEmitter
      .subscribe { [weak self] in
        self?.objectWillChange.send()
      } finished: { [weak self] in
        self?.disposable?.dispose()
        self?.disposable = nil
      }
  }

  // MARK: Private

  private var disposable: AutoDisposable?

}
