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
    self.disposable = observed.start { [disposable] in
      disposable?.dispose()
    }
  }

  public init(projectedValue: TreeNode<N>) {
    self.scope = projectedValue.scope
    self.observed = .init(scope: projectedValue.scope)
    self.disposable = observed.start { [disposable] in
      disposable?.dispose()
    }
  }

  // MARK: Public

  @_spi(Implementation) public let scope: NodeScope<N>

  public var nid: NodeID {
    scope.nid
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

  // MARK: Private

  private var disposable: AnyDisposable?
}

// MARK: Identifiable

extension TreeNode: Identifiable where N: Identifiable {
  public var id: CUID {
    assert(scope.node.cuid != nil)
    return scope.node.cuid ?? .invalid
  }
}
