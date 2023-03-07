// MARK: - UninitializedNode

struct UninitializedNode {
  let capture: NodeCapture
  let runtime: Runtime
}

extension UninitializedNode {

  // MARK: Internal

  @TreeActor
  func initialize<N: Node>(
    as _: N.Type,
    depth: Int,
    dependencies: DependencyValues,
    on route: RouteSource
  ) throws -> InitializedNode<N> {
    let existingRecord = runtime
      .getRoutedRecord(at: route)
    let record = existingRecord ?? createRecord(for: route)
    return try initialize(
      as: N.self,
      depth: depth,
      dependencies: dependencies,
      record: record
    )
  }

  @TreeActor
  func initialize<N: Node>(
    as _: N.Type,
    depth: Int,
    dependencies: DependencyValues,
    record: NodeRecord
  ) throws -> InitializedNode<N> {
    guard let node = capture.anyNode as? N
    else {
      runtimeWarning("Node type mismatch")
      throw NodeInitializationError()
    }

    let nodeID = record.id
    guard capture.fields.count == record.records.count
    else {
      runtimeWarning("Node field count mismatch")
      throw NodeInitializationError()
    }

    for i in 0 ..< record.records.count {
      let captureField = capture.fields[i]
      let fieldRecord = record.records[i]
      switch (captureField, fieldRecord.type) {
      case (.dependency(let field), .dependency):
        field.value.inner.dependencies = dependencies
      case (.projection(let field), .projection):
        field.value.projectionContext = .init(
          runtime: runtime,
          fieldID: fieldRecord.id
        )
      case (.scope(let field), .scope):
        field.value.inner.treeScope = .init(
          runtime: runtime,
          id: nodeID
        )
      case (.route(let field), .route):
        field.value.connection = .init(
          runtime: runtime,
          fieldID: fieldRecord.id
        )
      case (.value(let field, _), .value):
        field.value.access.treeValue = .init(
          runtime: runtime,
          id: fieldRecord.id
        )
      case (.unmanaged, .unmanaged):
        continue
      default:
        throw NodeInitializationError()
      }
    }
    return .init(
      id: nodeID,
      node: node,
      dependencies: dependencies,
      depth: depth,
      initialCapture: capture,
      nodeRecord: record,
      runtime: runtime
    )
  }

  // MARK: Private

  /// Create the node record—the underlying state that can be added to the tree.
  @TreeActor
  private func createRecord(for route: RouteSource) -> NodeRecord {
    let nodeID = route.nodeID == .system ? .root : NodeID()

    let fieldRecords: [FieldRecord] = capture
      .fields
      .enumerated()
      .map { offset, field in
        switch field {
        case .dependency:
          let fieldID = FieldID(
            type: .dependency,
            nodeID: nodeID,
            offset: offset
          )
          return FieldRecord(
            id: fieldID,
            payload: nil
          )
        case .projection(let projection):
          let fieldID = FieldID(
            type: .projection,
            nodeID: nodeID,
            offset: offset
          )
          return FieldRecord(
            id: fieldID,
            payload: .projection(projection.value.source)
          )
        case .route:
          let fieldID = FieldID(
            type: .route,
            nodeID: nodeID,
            offset: offset
          )
          // NOTE: route records are always created with no sub-routes.
          return FieldRecord(
            id: fieldID,
            payload: .route(route.emptyRecord())
          )
        case .scope:
          let fieldID = FieldID(
            type: .scope,
            nodeID: nodeID,
            offset: offset
          )
          return FieldRecord(
            id: fieldID,
            payload: nil
          )
        case .value(_, let initial):
          let fieldID = FieldID(
            type: .value,
            nodeID: nodeID,
            offset: offset
          )
          return FieldRecord(
            id: fieldID,
            payload: .value(initial.anyTreeState)
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
