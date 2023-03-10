import Foundation

/// FIXME: add randomness because the hash is probable terrible.
public struct BehaviorID: TreeState, CustomStringConvertible {

  // MARK: Lifecycle

  init(
    fileID: String,
    line: Int,
    column: Int,
    custom: String?
  ) {
    let info = "\(fileID):\(line):\(column)"
    let hashString = SipHasher.hash(Data(info.utf8))
    #if DEBUG
    self.debugInfo = info
    #endif
    self.id = custom ?? hashString
  }

  // MARK: Public

  /// A custom, or build-stable, identifier associated with a ``Behavior``.
  ///
  /// If a custom string identifier is passed to the Behavior it is used.
  /// If not an id is generated based on the source code location of the behavior's initialization.
  ///
  /// > Warning: An auto-generated BehaviorID will be stable only as long as the code around
  /// it remains unchanged. Prefer custom identifiers when testing Behavior identity.
  public let id: String

  public var description: String {
    #if DEBUG
    ".id(\(id))"
    #else
    id
    #endif
  }

  public static func auto(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column
  )
    -> BehaviorID
  {
    runtimeWarning(
      "Autocreated BehaviorIDs will change if their call-site changes. Use a custom id when testing behaviors."
    )
    return self.init(fileID: fileID, line: line, column: column, custom: nil)
  }

  public static func id(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: String
  )
    -> BehaviorID
  {
    .init(fileID: fileID, line: line, column: column, custom: id)
  }

  public static func == (lhs: BehaviorID, rhs: BehaviorID) -> Bool {
    lhs.id == rhs.id
  }

  public func encode(to encoder: Encoder) throws {
    // Note: encode dropping code location information in debug.
    var container = encoder.singleValueContainer()
    try container.encode(id)
  }

  // MARK: Internal

  static var invalid: BehaviorID {
    .init(fileID: "invalid", line: -1, column: -1, custom: "invalid")
  }

  // MARK: Private

  #if DEBUG
  /// file, line, column information available in DEBUG builds only.
  private let debugInfo: String
  #endif
}
