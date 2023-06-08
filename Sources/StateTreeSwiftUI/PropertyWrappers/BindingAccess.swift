@_spi(Implementation) import StateTree
import SwiftUI
import Utilities

// MARK: - BindingAccess

@dynamicMemberLookup
@TreeActor
public protocol BindingAccess {
  associatedtype NodeType: Node
  @_spi(Implementation) var scope: NodeScope<NodeType> { get }
}

extension BindingAccess {
  public subscript<T>(
    dynamicMember dynamicMember: WritableKeyPath<NodeType, T>
  ) -> Binding<T> {
    .init {
      scope.node[keyPath: dynamicMember]
    } set: { newValue in
      var node = scope.node
      node[keyPath: dynamicMember] = newValue
    }
  }
}
