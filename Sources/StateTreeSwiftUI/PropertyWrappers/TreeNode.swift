import Combine
import Disposable
@_spi(Implementation) import StateTree
import SwiftUI

// MARK: - TreeNode

@propertyWrapper
@dynamicMemberLookup
public struct TreeNode<N: Node>: DynamicProperty, NodeAccess {

  // MARK: Lifecycle

  init(scope: NodeScope<N>) {
    self.scope = scope
    self.observed = .init(scope: scope)
    self.nid = scope.nid
    self.cuid = scope.cuid
    observed.startIfNeeded()
  }

  public init(projectedValue: TreeNode<N>) {
    self = projectedValue
    observed.startIfNeeded()
  }

  // MARK: Public

  @_spi(Implementation) public let scope: NodeScope<N>

  public var wrappedValue: N {
    scope.node
  }

  public var projectedValue: TreeNode<N> {
    self
  }

  // MARK: Internal

  let nid: NodeID
  let cuid: CUID?

  @ObservedObject var observed: ObservableNode<N>

  var runtime: Runtime {
    scope.runtime
  }

  var node: N {
    scope.node
  }

  // MARK: Private

  private var disposable: AutoDisposable?
}

// MARK: Identifiable

extension TreeNode: Identifiable where N: Identifiable {
  public var id: CUID {
    cuid ?? .invalid
  }
}
