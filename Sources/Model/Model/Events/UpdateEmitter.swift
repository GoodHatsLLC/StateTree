import Emitter
import Foundation

// MARK: - UpdateEmitter

@MainActor
public struct UpdateEmitter<M: Model> {
  init(_ storage: _ModelStorage<M>) {
    self.storage = storage
  }

  public var routesDidChange: some Emitter<UUID> {
    storage.routesDidChange
  }

  public var stateDidChange: some Emitter<UUID> {
    storage.stateDidChange
  }

  public var observedStateDidChange: some Emitter<UUID> {
    storage.observedStateDidChange
  }

  public var subtreeDidChange: some Emitter<UUID> {
    storage.subtreeDidChange
  }

  public var observedSubtreeDidChange: some Emitter<UUID> {
    storage.observedSubtreeDidChange
  }

  public var didChangeValidity: some Emitter<Bool> {
    storage.didChangeValidity
  }

  private let storage: _ModelStorage<M>

}
