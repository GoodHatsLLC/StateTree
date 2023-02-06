// MARK: - InitializedNode

struct InitializedNode<N: Node> {
  let id: NodeID
  let node: N
  let dependencies: DependencyValues
  let depth: Int
  let initialCapture: NodeCapture
  let nodeRecord: NodeRecord
  let runtime: Runtime
}

extension InitializedNode {

  @TreeActor
  func connect() throws -> NodeScope<N> {
    let scope = NodeScope(self, dependencies: dependencies, depth: depth)
    runtime.connect(scope: scope.erase())
    return scope
  }

  func getValueDependencies() -> Set<FieldID> {
    Set(
      nodeRecord
        .records
        .compactMap { record in
          switch record.payload {
          case .projection(let source):
            if case .valueField(let field) = source {
              return field
            }
          case .value:
            return record.id
          case _:
            return nil
          }
          return nil
        }
    )
  }

  func erase() -> AnyInitializedNode {
    AnyInitializedNode(self)
  }

}
