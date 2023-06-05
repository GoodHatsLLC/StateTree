// MARK: - RouteType

public enum RouteType: String, TreeState {
  case single
  case union2
  case union3
  case maybeSingle
  case maybeUnion2
  case maybeUnion3
  case list
}

// MARK: - RouteID

public struct RouteID {
  public init(fieldID: FieldID, identity: LSID? = nil) {
    self.fieldID = fieldID
    self.identity = identity
  }

  public let fieldID: FieldID
  public let identity: LSID?
}

// MARK: - RouteSource

public struct RouteSource: TreeState, CustomStringConvertible {

  // MARK: Public

  public let fieldID: FieldID
  public let identity: LSID?
  public let type: RouteType
  public let depth: Int

  public var routeID: RouteID {
    .init(fieldID: fieldID, identity: identity)
  }

  public var description: String {
    "\(type) \(fieldID)\(identity.map { ":i-\($0)" } ?? "")@\(depth)"
  }

  public var nodeID: NodeID {
    fieldID.nodeID
  }

  // MARK: Internal

  static let system: RouteSource = .init(
    fieldID: .system,
    identity: nil,
    type: .single,
    depth: 0
  )

  static var invalid: RouteSource {
    assertionFailure("the invalid RouteSource should never be used")
    let field = FieldID.invalid
    return .init(fieldID: field, identity: .none, type: .single, depth: -1)
  }
}
