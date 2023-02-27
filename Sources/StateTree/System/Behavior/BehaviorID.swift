import Crypto
import Foundation

public struct BehaviorID: TreeState, CustomStringConvertible {

  // MARK: Lifecycle

  init(
    fileID: String,
    line: Int,
    column: Int,
    custom: String?
  ) {
    let info = "\(fileID):\(line):\(column)"
    let data = Data(info.utf8)
    let hash = SHA256.hash(data: data)
    let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
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
  /// it remains fully unchanged. Prefer custom identifiers when testing Behavior identity.
  public let id: String

  public var description: String {
    #if DEBUG
    id + " (\(debugInfo))"
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
      "Autocreated BehaviorIDs will change if their callsite changes. Use a custom id when testing behaviors."
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

  // MARK: Private

  #if DEBUG
  /// file, line, column information available in DEBUG builds only.
  private let debugInfo: String
  #endif
}
