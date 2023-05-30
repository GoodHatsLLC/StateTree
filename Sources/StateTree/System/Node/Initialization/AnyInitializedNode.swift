import OrderedCollections
import TreeActor

// MARK: - AnyInitializedNode

struct AnyInitializedNode {
  init(_ node: InitializedNode<some Node>) {
    self.id = node.id
    self.nodeRecord = node.nodeRecord
    self.runtime = node.runtime
    self.node = node.node
    self.connectFunc = {
      try node.connect().erase()
    }
    self.valueFieldDependenciesFunc = {
      node.getValueDependencies()
    }
  }

  let id: NodeID
  let nodeRecord: NodeRecord
  let runtime: Runtime
  let node: any Node

  private let connectFunc: @TreeActor () throws -> AnyScope
  private let valueFieldDependenciesFunc: () -> OrderedSet<FieldID>
}

extension AnyInitializedNode {

  @TreeActor
  func connect() throws -> AnyScope {
    try connectFunc()
  }

  func getValueDependencies() -> OrderedSet<FieldID> {
    valueFieldDependenciesFunc()
  }

}
