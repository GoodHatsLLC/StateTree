import Combine
import StateTree
import SwiftUI

/// @PublishedModel is a property wrapper which allows an `ObservableObject`
/// containing a model to notify SwiftUI of the model's changes.
///
/// ```swift
/// @PublishedModel private var model: MyModel
/// ```
///
/// The contained model's notifications are proxied to the outer `ObservableObject`
/// allowing SwiftUI to update based on the model's changes.
///
/// The outer `ObservableObject` can then provide accessors mapping the model data.
///
/// Proxied accessors are not marked as `@Published` since they don't contain
/// stored data.
/// (If the `ObservableObject` does store state, the state fields should be `@Published`
/// so that they trigger SwiftUI updates conventionally. Note that this state would be intermediate
/// view layer state and wouldn't be managed by the `StateTree`.)
///
/// ```swift
/// var proxiedInfo: String { "\(model.info)" }
/// @Published var unmanagedState: String = "StateTree is unaware of this field."
/// ```
@MainActor
@propertyWrapper
public final class PublishedModel<Republishing: Model> {

  public init(wrappedValue: Republishing) {
    _republished = wrappedValue
  }

  @available(*, unavailable, message: "@PublishedModel can only be used in an ObservableObject")
  public var wrappedValue: Republishing {
    get {
      fatalError("@PublishedModel can only be used in an ObservableObject")
    }
    set {
      fatalError("@PublishedModel can only be used in an ObservableObject")
    }
  }

  public var projectedValue: Binding<Republishing> {
    _republished.projection.binding()
  }

  public static subscript<
    Instance: ObservableObject
  >(
    _enclosingInstance instance: Instance,
    wrapped _: ReferenceWritableKeyPath<Instance, Republishing>,
    storage storageKeyPath: ReferenceWritableKeyPath<Instance, PublishedModel>
  )
    -> Republishing where Instance.ObjectWillChangePublisher == ObservableObjectPublisher
  {
    get {
      let storage = instance[keyPath: storageKeyPath]
      // make only one subscription
      if storage.disposable == nil {
        let objectWillChangePublisher = instance.objectWillChange
        let events = storage._republished.store.events

        storage.disposable = events.observedSubtreeDidChange
          .merge(events.routesDidChange)
          .removeDuplicates()
          .subscribe { _ in
            DependencyValues.defaults.logger.log(
              message: "PublishedModel notified ObservableObject",
              self,
              instance
            )
            objectWillChangePublisher.send()
          }
      }
      return storage._republished
    }
    set {
      let storage = instance[keyPath: storageKeyPath]
      storage._republished = newValue
      // end any current subscription if the model is changed.
      storage.disposable = nil
    }
  }

  private var _republished: Republishing
  private var disposable: AnyDisposable?

}
