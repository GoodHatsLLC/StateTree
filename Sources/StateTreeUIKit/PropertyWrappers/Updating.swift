import Disposable
import Foundation
import Model

// MARK: - Updating

/// A property wrapper whose projected value allows registering callbacks for model state change.
@MainActor
@propertyWrapper
public struct Updating<M: Model> {
  public init(wrappedValue: M) {
    self.wrappedValue = wrappedValue
  }

  public var wrappedValue: M

  public lazy var projectedValue = Updater<M>(model: wrappedValue)
}

// MARK: - Updater

/// A subscriber to Model state changes allowing registering callbacks with ``onChange(owner:handler:)``
@MainActor
public final class Updater<M: Model> {
  init(model: M) {
    self.model = model

    disposable = subscribeForChanges()
  }

  /// Register `handler` callbacks which receive the current state and subsequent updates
  ///
  /// Parameters:
  /// - `owner`: Any object whose lifecycle the registration is bound to.
  /// - `handler`: The callback firing initially on registration and on change.
  ///
  /// - Note: `owner` is held weakly and its associated handler is disposed once it is released.
  public func onChange<T: AnyObject>(
    owner ref: T,
    handler: @escaping (_ this: T, _ model: M) -> Void
  ) {
    let weakRef = WeakRef(ref)
    let anyWeakRef = AnyWeakRef(ref)
    let wrappedCallback = { state in
      if let ref = weakRef.ref {
        handler(ref, state)
      }
    }
    callbacks[anyWeakRef, default: []].append(wrappedCallback)
    _ = wrappedCallback(model)
  }

  /// Unregister all callback with the passed owner
  ///
  /// This allows unregistering without the owner deallocating
  public func unregister<T: AnyObject>(owner: T) {
    let anyWeakRef = WeakRef<AnyObject>(owner)
    callbacks[anyWeakRef] = nil
  }

  private let model: M
  private var disposable: AnyDisposable?
  private var callbacks: [WeakRef<AnyObject>: [(M) -> Void]] = [:]

  private func subscribeForChanges() -> AnyDisposable {
    model.store
      .events
      .observedStateDidChange
      .merge(model.store.events.routesDidChange)
      .subscribe { [weak self] _ in
        if let self = self {
          self.fireUpdate(model: self.model)
        }
      }
  }

  private func fireUpdate(model: M) {
    guard model.store._storage.isValid()
    else {
      callbacks = [:]
      return
    }

    // collect false returns indicating released owners
    var releasedOwners: [WeakRef<AnyObject>] = []

    // call callbacks
    for entry in callbacks {
      let ref = entry.key
      let callbacks = entry.value
      if ref.ref == nil {
        releasedOwners.append(ref)
        continue
      }
      for callback in callbacks {
        callback(model)
      }
    }

    // remove where ref is now deallocated
    for releasedOwner in releasedOwners {
      callbacks[releasedOwner] = nil
    }
  }

}
