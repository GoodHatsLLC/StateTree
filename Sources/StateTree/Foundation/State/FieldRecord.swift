import Utilities

// MARK: - FieldRecord

struct FieldRecord: Codable {

  let id: FieldID
  var payload: FieldRecordPayload?

  var type: FieldType {
    id.type
  }
}

// MARK: - FieldRecordPayload

/// The underlying representation of a ``Node`` field managed by StateTree.
enum FieldRecordPayload: Codable {

  /// `@Projection` (``Projection``) field on ``Node``.
  case projection(ProjectionSource)

  /// `@Route` (``Route``) field on a ``Node``.
  case route(RouteRecord)

  /// `@Value` (``Value``) field on a ``Node``.
  case value(ValuePayload)

}

// MARK: - TypeDescription

struct TypeDescription: Codable, Hashable {
  let description: String
}

// MARK: - ValueRecord

struct ValueRecord: Codable, Hashable {
  let id: FieldID
  let value: ValuePayload
}

// MARK: - ProjectionSource

/// The source of a `Projection` — used for dependency analysis.
public enum ProjectionSource: Codable, Hashable {
  case valueField(FieldID)
  case programmatic
  case invalid
}

extension FieldRecord {
  func value() -> ValuePayload? {
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
