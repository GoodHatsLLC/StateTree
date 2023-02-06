#if !CUSTOM_ACTOR
import Combine
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
          .filter { [nodeID = storage.projectedValue.id] in $0 == nodeID }
          .subscribe { _ in
            objectWillChangePublisher.send()
          }
      }
      return storage.projectedValue.node
    }
    set { }
  }

  // MARK: Private

  private var disposable: AnyDisposable?

}
#endif
