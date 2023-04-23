import Combine
import Disposable
@_spi(Implementation) import StateTree
import SwiftUI

/// `@PublishedNode` is a property wrapper which allows a StateTree `Node`
/// to be used within an `ObservableObject`.
///
///
/// The node's updates are surfaced via the `ObservableObject` to update SwiftUI of changes.
///
/// ```swift
/// @PublishedNode private var model: MyNode
/// ```
@MainActor
@propertyWrapper
public final class PublishedNode<N: Node> {

  // MARK: Lifecycle

  public init(projectedValue: TreeNode<N>) {
    self.projectedValue = projectedValue
  }

  // MARK: Public

  public let projectedValue: TreeNode<N>

  @available(
    *,
    unavailable,
    message: "@PublishedNode can only be used in an ObservableObject"
  ) public var wrappedValue: N {
    get {
      fatalError("@PublishedNode can only be used in an ObservableObject")
    }
    set {
      fatalError("@PublishedNode can only be used in an ObservableObject")
    }
  }

  public static subscript<
    Instance: ObservableObject
  >(
    _enclosingInstance instance: Instance,
    wrapped _: ReferenceWritableKeyPath<Instance, N>,
    storage storageKeyPath: ReferenceWritableKeyPath<Instance, PublishedNode>
  )
    -> N where Instance.ObjectWillChangePublisher == ObservableObjectPublisher
  {
    get {
      let storage = instance[keyPath: storageKeyPath]
      // make only one subscription
      if storage.disposable == nil {
        let objectWillChangePublisher = instance.objectWillChange

        storage.disposable = storage
          .projectedValue
          .runtime
          .updateEmitter
          .compactMap(\.maybeNode)
          .compactMap { [nodeID = storage.projectedValue.nid] change in
            switch change {
            case .update(let updatedID, _) where updatedID == nodeID:
              return ChangeEvent.update
            case .stop(let stoppedID, _) where stoppedID == nodeID:
              return ChangeEvent.stop
            default: return nil
            }
          }
          .subscribe { (change: ChangeEvent) in
            switch change {
            case .update:
              objectWillChangePublisher.send()
            case .stop:
              storage.disposable?.dispose()
            }
          }
      }
      return storage.projectedValue.node
    }
    set { }
  }

  // MARK: Internal

  enum ChangeEvent {
    case update
    case stop
  }

  // MARK: Private

  private var disposable: AutoDisposable?

}
