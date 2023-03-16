// MARK: - RouteID

public struct RouteSource: TreeState, CustomDebugStringConvertible {

  // MARK: Public

  public enum RouteType: String, TreeState {
    case single
    case union2
    case union3
    case list
  }

  public let fieldID: FieldID
  public let identity: CUID?
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

  func emptyRecord() -> RouteRecord {
    switch type {
    case .single:
      .single(nil)
    case .union2:
      .union2(nil)
    case .union3:
      .union3(nil)
    case .list:
      .list(nil)
    }
  }
}
