import Foundation
import Utilities

/// A custom, or build-stable, identifier associated with a ``Behavior``.
///
/// If a custom `.id("value")` identifier is passed to the `Behavior` it is used.
/// If not a  `.auto()` is generated based on the source code location of the behavior's
/// initialization.
///
/// - ``id(fileID:line:column:_:)
/// - ``auto(fileID:line:column:)``
///
/// > Warning: An auto-generated `BehaviorID` will be stable only as long as the code around
/// it remains unchanged. Prefer custom identifiers when testing `Behavior` identity.
public struct BehaviorID: Sendable & Equatable & Hashable & Codable, CustomStringConvertible {

  // MARK: Lifecycle

  private init(
    fileID: String,
    line: Int,
    column: Int,
    metadata: String?
  ) {
    let info = "\(fileID):\(line):\(column)"
    let hashString = StableHasher.hash(Data(info.utf8))
    #if DEBUG
    self.debugInfo = info
    #endif

    if let metadata {
      self.value = hashString + "-\(metadata)"
    } else {
      self.value = hashString
    }
  }

  private init(
    value: String,
    debugInfo: String?
  ) {
    #if DEBUG
    self.debugInfo = debugInfo
    #endif
    self.value = value
  }

  // MARK: Public

  public var id: String {
    value
  }

  public var description: String {
    ".id(\"\(value)\")"
  }

  public static func auto(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column
  )
    -> BehaviorID
  {
    self.init(fileID: fileID, line: line, column: column, metadata: "auto")
  }

  @_spi(Implementation)
  public static func meta(
    fileID: String,
    line: Int,
    column: Int,
    meta: String
  )
    -> BehaviorID
  {
    self.init(fileID: fileID, line: line, column: column, metadata: meta)
  }

  public static func id(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: String
  )
    -> BehaviorID
  {
    .init(value: id, debugInfo: "\(fileID):\(line):\(column)")
  }

  public static func == (lhs: BehaviorID, rhs: BehaviorID) -> Bool {
    lhs.value == rhs.value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func encode(to encoder: Encoder) throws {
    // Note: encode dropping code location information in debug.
    var container = encoder.singleValueContainer()
    try container.encode(id)
  }

  // MARK: Internal

  static var invalid: BehaviorID {
    .init(value: "invalid", debugInfo: nil)
  }

  // MARK: Private

  private let value: String

  #if DEBUG
  /// file, line, column information available in DEBUG builds only.
  private let debugInfo: String?
  #endif
}
