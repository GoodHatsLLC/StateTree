// MARK: - RouteType

public enum RouteType: String, Codable, Hashable {
  case single
  case union2
  case union3
  case list

  func emptyRecord() -> RouteRecord {
    switch self {
    case .single:
      return .single(nil)
    case .union2:
      return .union2(nil)
    case .union3:
      return .union3(nil)
    case .list:
      return .list(.init(idMap: [:]))
    }
  }
}

// MARK: - RouteSource

public struct RouteSource: Codable, Hashable, CustomDebugStringConvertible {

  // MARK: Public

  public let fieldID: FieldID
  public let identity: LSID?
  public let type: RouteType

  public var debugDescription: String {
    "\(type)" + fieldID.description + "\(identity.map { " identity: \($0)" } ?? "")"
  }

  public var nodeID: NodeID {
    fieldID.nodeID
  }

  // MARK: Internal

  static var system: RouteSource {
    let field = FieldID.system
    return .init(fieldID: field, identity: .none, type: .single)
  }

  static var invalid: RouteSource {
    assertionFailure("the invalid RouteSource should never be used")
    let field = FieldID.invalid
    return .init(fieldID: field, identity: .none, type: .single)
  }
}
