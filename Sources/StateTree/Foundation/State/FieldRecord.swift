import TreeState

// MARK: - FieldRecord

struct FieldRecord: TreeState {
  struct SourceFieldMetadata: TreeState {
    let label: String?
    let typeof: String
  }

  let id: FieldID
  let meta: SourceFieldMetadata
  var payload: FieldRecordPayload?

  var type: FieldType {
    id.type
  }
}

// MARK: - FieldRecordPayload

/// The underlying representation of a ``Node`` field managed by StateTree.
enum FieldRecordPayload: TreeState {

  /// `@Projection` (``Projection``) field on ``Node``.
  case projection(ProjectionSource)

  /// `@Route` (``Route``) field on a ``Node``.
  case route(RouteRecord)

  /// `@Value` (``Value``) field on a ``Node``.
  case value(AnyTreeState)

}

// MARK: - TypeDescription

struct TypeDescription: TreeState {
  let description: String
}

// MARK: - ValueRecord

struct ValueRecord: TreeState {
  let id: FieldID
  let value: AnyTreeState
}

// MARK: - ProjectionSource

/// The source of a `Projection` — used for dependency analysis.
enum ProjectionSource: TreeState {
  case valueField(FieldID)
  case programmatic
  case invalid
}

extension FieldRecord {
  func value() -> AnyTreeState? {
    if case .value(let valueRecord) = payload {
      return valueRecord
    }
    return nil
  }

  func route() -> RouteRecord? {
    if case .route(let routeRecord) = payload {
      return routeRecord
    }
    return nil
  }

  func projection() -> ProjectionSource? {
    if case .projection(let projectionRecord) = payload {
      return projectionRecord
    }
    return nil
  }
}
