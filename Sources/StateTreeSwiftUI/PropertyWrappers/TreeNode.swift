#if !CUSTOM_ACTOR
import Combine
import Disposable
@_spi(Implementation) import StateTree
import SwiftUI

// MARK: - TreeNode

@MainActor
@propertyWrapper
@dynamicMemberLookup
public struct TreeNode<N: Node>: DynamicProperty, NodeAccess {

  // MARK: Lifecycle

  init(scope: NodeScope<N>) {
    self.scope = scope
    self.observed = .init(scope: scope)
  }

  public init(projectedValue: TreeNode<N>) {
    self.scope = projectedValue.scope
    self.observed = .init(scope: projectedValue.scope)
  }

  // MARK: Public

  @_spi(Implementation) public let scope: NodeScope<N>

  public var id: NodeID {
    scope.id
  }

  public var wrappedValue: N {
    scope.node
  }

  public var projectedValue: TreeNode<N> {
    self
  }

  // MARK: Internal

  @ObservedObject var observed: ObservableNode<N>

  var runtime: Runtime {
    scope.runtime
  }

  var node: N {
    scope.node
  }

}
#endif
