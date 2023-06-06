import Combine
import Disposable
@_spi(Implementation) import StateTreeBase
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
public final class PublishedNode<NodeType: Node> {

  // MARK: Lifecycle

  public init(projectedValue: TreeNode<NodeType>) {
    self.projectedValue = projectedValue
  }

  // MARK: Public

  public let projectedValue: TreeNode<NodeType>

  @available(
    *,
    unavailable,
    message: "@PublishedNode can only be used in an ObservableObject"
  ) public var wrappedValue: NodeType {
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
    wrapped _: ReferenceWritableKeyPath<Instance, NodeType>,
    storage storageKeyPath: ReferenceWritableKeyPath<Instance, PublishedNode>
  )
    -> NodeType where Instance.ObjectWillChangePublisher == ObservableObjectPublisher
  {
    get {
      let storage = instance[keyPath: storageKeyPath]
      // make only one subscription
      if storage.disposable == nil {
        let objectWillChangePublisher = instance.objectWillChange

        storage.disposable = storage
          .projectedValue
          .scope
          .didUpdateEmitter
          .subscribe {
            objectWillChangePublisher.send()
          } finished: {
            storage.disposable?.dispose()
          }
      }
      return storage.projectedValue.node
    }
    set { }
  }

  // MARK: Private

  private var disposable: AutoDisposable?

}
