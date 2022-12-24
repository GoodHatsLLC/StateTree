import Combine
import Disposable
import Emitter
import Foundation
import Model
import SwiftUI

// MARK: - ObservableModel

@MainActor
public final class ObservableModel<M: Model>: ObservableObject {
  init(model: M) {
    self.model = model
    disposable = start()
  }

  public var model: M

  func start() -> AnyDisposable {
    // Listen for changes made in which this model
    // is the lowest level one changing.
    let events = model.store.events
    return events.observedSubtreeDidChange
      .merge(events.routesDidChange)
      .removeDuplicates()
      .subscribe { [weak self] _ in
        // Emit to SwiftUI.
        self?.objectWillChange.send()
      }
  }

  private var disposable: AnyDisposable?

}
