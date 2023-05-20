// MARK: - RouteType

public enum RouteType: String, Codable, Hashable {
  case single
  case union2
  case union3
  case maybeSingle
  case maybeUnion2
  case maybeUnion3
  case list
}

// MARK: - RouteSource

public struct RouteSource: Codable, Hashable, CustomStringConvertible {

  static let system: RouteSource = .init(
    fieldID: .system,
    identity: nil,
    type: .single,
    depth: 0
  )

  // MARK: Public

  public let fieldID: FieldID
  public let identity: LSID?
  public let type: RouteType
  public let depth: Int

  public var description: String {
    "\(type) \(fieldID)\(identity.map { ":i-\($0)" } ?? "")@\(depth)"
  }

  public var nodeID: NodeID {
    fieldID.nodeID
  }

  // MARK: Internal

  static var invalid: RouteSource {
    assertionFailure("the invalid RouteSource should never be used")
    let field = FieldID.invalid
    return .init(fieldID: field, identity: .none, type: .single, depth: -1)
  }
}
