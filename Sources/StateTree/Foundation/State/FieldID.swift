// MARK: - FieldID

/// The unique identifier of each ``Node`` field tracked by StateTree.
public struct FieldID: TreeState, LosslessStringConvertible {

  // MARK: Lifecycle

  init(type: FieldType, nodeID: NodeID, offset: Int) {
    self.type = type
    self.nodeID = nodeID
    self.offset = offset
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    guard let this = FieldID(string)
    else {
      throw MemberIDDecodingError(payload: string)
    }
    self = this
  }

  public init?(_ description: String) {
    let components = description.split(
      maxSplits: 2,
      omittingEmptySubsequences: false,
      whereSeparator: { $0 == ":" }
    )
    guard
      components.count == 3,
      let type = FieldType(String(components[0])),
      let offset = Int(components[1]),
      let nodeID = NodeID(String(components[2]))
    else {
      return nil
    }
    self.nodeID = nodeID
    self.type = type
    self.offset = offset
  }

  // MARK: Public

  public var description: String {
    "\(type.description):\(offset):\(nodeID.description)"
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }

  // MARK: Internal

  let type: FieldType
  let nodeID: NodeID
  let offset: Int

}

extension FieldID {

  /// A custom invalid ``MemberID`` which should never be present in serialised output.
  ///
  /// (Contains the invalid ``NodeID`` `"00000000-0000-0000-0000-000000000000:❌"` )
  static var invalid: FieldID {
    assertionFailure("the invalid FieldID should never be used")
    return .init(type: .unmanaged, nodeID: .invalid, offset: -1)
  }

  /// A custom `MemberID` identifying the StateTree system as the source of the root node.
  static var system: FieldID {
    .init(type: .route, nodeID: .system, offset: 0)
  }

}

// MARK: Identifiable

extension FieldID: Identifiable {
  public var id: String {
    description
  }
}

// MARK: - MemberIDDecodingError

struct MemberIDDecodingError: Error {
  let payload: String
  var localizedDescription: String {
    "could not decode from: \(payload)"
  }
}
