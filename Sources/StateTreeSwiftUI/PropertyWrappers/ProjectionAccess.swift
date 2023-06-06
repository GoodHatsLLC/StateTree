@_spi(Implementation) import StateTree
import SwiftUI
import Utilities

// MARK: - ProjectionAccess

@dynamicMemberLookup
@TreeActor
public protocol ProjectionAccess {
  associatedtype NodeType: Node
  @_spi(Implementation) var scope: NodeScope<NodeType> { get }
}

extension ProjectionAccess {
  public subscript<T>(
    dynamicMember dynamicMember: KeyPath<NodeType, Projection<T>>
  ) -> Binding<T> {
    scope.node[keyPath: dynamicMember].binding()
  }
}
