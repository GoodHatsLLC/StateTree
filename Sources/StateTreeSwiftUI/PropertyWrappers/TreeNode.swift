import Combine
import Disposable
@_spi(Implementation) import StateTree
import SwiftUI
import Utilities

// MARK: - TreeNode + ScopeAccess

extension TreeNode: ScopeAccess { }

// MARK: - TreeNode

@propertyWrapper
@dynamicMemberLookup
public struct TreeNode<NodeType: Node>: DynamicProperty, RouterAccess, ProjectionAccess,
  BindingAccess
{

  // MARK: Lifecycle

  init(scope: NodeScope<NodeType>) {
    self.scope = scope
    self.observed = .init(scope: scope)
    self.nid = scope.nid
    observed.startIfNeeded()
  }

  public init(projectedValue: TreeNode<NodeType>) {
    self = projectedValue
    observed.startIfNeeded()
  }

  // MARK: Public

  @_spi(Implementation) public let scope: NodeScope<NodeType>

  @_spi(Implementation) public var access: TreeNode<NodeType> { self }

  public var wrappedValue: NodeType {
    get {
      scope.node
    }
    nonmutating set {
      runtimeWarning("A tree node's node can not be changed.")
    }
  }

  public var projectedValue: TreeNode<NodeType> {
    self
  }

  // MARK: Internal

  let nid: NodeID

  @ObservedObject var observed: ObservableNode<NodeType>

  var runtime: Runtime {
    scope.runtime
  }

  var node: NodeType {
    scope.node
  }

  // MARK: Private

  private var disposable: AutoDisposable?
}
