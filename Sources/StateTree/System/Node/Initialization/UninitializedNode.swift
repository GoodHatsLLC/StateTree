import TreeActor
import Utilities

// MARK: - UninitializedNode

struct UninitializedNode {
  let capture: NodeCapture
  let runtime: Runtime
}

extension UninitializedNode {

  // MARK: Internal

  @TreeActor
  func initializeRoot<N: Node>(
    asType _: N.Type,
    dependencies: DependencyValues
  ) throws -> InitializedNode<N> {
    try initializeNode(
      asType: N.self,
      id: .root,
      dependencies: dependencies,
      on: .system
    )
  }

  @TreeActor
  func initializeNode<N: Node>(
    asType _: N.Type,
    id nodeID: NodeID = NodeID(),
    dependencies: DependencyValues,
    on route: RouteSource
  ) throws -> InitializedNode<N> {
    guard let node = capture.anyNode as? N
    else {
      runtimeWarning("Node type mismatch")
      throw NodeInitializationError()
    }
    let record = createRecord(
      id: nodeID,
      on: route,
      dependencies: dependencies
    )
    return .init(
      id: nodeID,
      node: node,
      dependencies: dependencies,
      depth: route.depth,
      initialCapture: capture,
      nodeRecord: record,
      runtime: runtime
    )
  }

  @TreeActor
  func renitializeRoot<N: Node>(
    asType _: N.Type,
    from record: NodeRecord,
    dependencies: DependencyValues
  ) throws -> InitializedNode<N> {
    try reinitializeNode(
      asType: N.self,
      from: record,
      at: .init(
        fieldID: .system,
        identity: nil,
        type: .single,
        depth: 0
      ),
      dependencies: dependencies
    )
  }

  @TreeActor
  func reinitializeNode<N: Node>(
    asType _: N.Type,
    from record: NodeRecord,
    at route: RouteSource,
    dependencies: DependencyValues
  ) throws -> InitializedNode<N> {
    let nodeID = record.id
    guard let node = capture.anyNode as? N
    else {
      runtimeWarning("Node type mismatch")
      throw NodeReinitializationError()
    }
    guard capture.fields.count == record.records.count
    else {
      runtimeWarning("Node field count mismatch")
      throw NodeReinitializationError()
    }

    for (capture, record) in zip(capture.fields, record.records) {
      assert(capture.fieldType == record.fieldType)

      switch capture {
      case .dependency(let field):
        field.value.inner.dependencies = dependencies

      case .projection(let field):
        field.value.projectionContext = .init(
          runtime: runtime,
          fieldID: record.id
        )

      case .scope(let field):
        field.value.inner.treeScope = .init(
          runtime: runtime,
          id: nodeID
        )

      case .route(let field):
        field.value
          .connect(
            .init(
              runtime: runtime,
              fieldID: record.id
            ),
            writeContext: .init(
              depth: route.depth,
              dependencies: dependencies
            )
          )

      case .value(let field, _):
        field.value.access.treeValue = .init(
          runtime: runtime,
          id: record.id
        )

      case .unmanaged:
        continue
      }
    }
    return .init(
      id: nodeID,
      node: node,
      dependencies: dependencies,
      depth: route.depth,
      initialCapture: capture,
      nodeRecord: record,
      runtime: runtime
    )
  }

  // MARK: Private

  @TreeActor
  /// Create the node record—the underlying state that can be added to the tree.
  private func createRecord(
    id nodeID: NodeID,
    on route: RouteSource,
    dependencies: DependencyValues
  )
    -> NodeRecord
  {
    let fieldRecords: [FieldRecord] = capture
      .fields
      .enumerated()
      .map { offset, field in
        switch field {
        case .dependency(let field):
          let fieldID = FieldID(
            type: .dependency,
            nodeID: nodeID,
            offset: offset
          )
          field.value.inner
            .dependencies = dependencies
          return FieldRecord(
            id: fieldID,
            payload: nil
          )
        case .projection(let field):
          let fieldID = FieldID(
            type: .projection,
            nodeID: nodeID,
            offset: offset
          )
          field.value
            .projectionContext = .init(
              runtime: runtime,
              fieldID: fieldID
            )
          return FieldRecord(
            id: fieldID,
            payload: .projection(
              field.value.source
            )
          )
        case .route(let field):
          let fieldID = FieldID(
            type: .route,
            nodeID: nodeID,
            offset: offset
          )
          field.value
            .connect(
              .init(
                runtime: runtime,
                fieldID: fieldID
              ),
              writeContext: .init(
                depth: route.depth,
                dependencies: dependencies
              )
            )
          return FieldRecord(
            id: fieldID,
            payload: .route(field.value.initialRecord)
          )
        case .scope(let field):
          let fieldID = FieldID(
            type: .scope,
            nodeID: nodeID,
            offset: offset
          )
          field.value.inner
            .treeScope = .init(
              runtime: runtime,
              id: nodeID
            )
          return FieldRecord(
            id: fieldID,
            payload: nil
          )
        case .value(let field, let initial):
          let fieldID = FieldID(
            type: .value,
            nodeID: nodeID,
            offset: offset
          )
          field.value.access
            .treeValue = .init(
              runtime: runtime,
              id: fieldID
            )
          return FieldRecord(
            id: fieldID,
            payload: .value(
              initial.anyPayload
            )
          )
        case .unmanaged:
          let fieldID = FieldID(
            type: .unmanaged,
            nodeID: nodeID,
            offset: offset
          )
          return FieldRecord(
            id: fieldID,
            payload: nil
          )
        }
      }
    return NodeRecord(
      id: nodeID,
      origin: route,
      records: fieldRecords
    )
  }
}

// MARK: - NodeInitializationError

struct NodeInitializationError: Error { }

// MARK: - NodeReinitializationError

struct NodeReinitializationError: Error { }
