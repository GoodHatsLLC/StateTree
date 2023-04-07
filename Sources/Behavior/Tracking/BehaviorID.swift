import Foundation
import Utilities

/// A custom, or build-stable, identifier associated with a ``Behavior``.
///
/// If a custom `.id("value")` identifier is passed to the `Behavior` it is used.
/// If not a  `.auto()` is generated based on the source code location of the behavior's
/// initialization.
///
/// - ``id(moduleFile:line:column:_:)``
/// - ``auto(moduleFile:line:column:)``
///
/// > Warning: An auto-generated `BehaviorID` will be stable only as long as the code around
/// it remains unchanged. Prefer custom identifiers when testing `Behavior` identity.
public struct BehaviorID: Sendable & Equatable & Hashable & Codable, CustomStringConvertible {

  // MARK: Lifecycle

  private init(
    moduleFile: String,
    line: Int,
    column: Int,
    metadata: String?
  ) {
    let info = "\(moduleFile):\(line):\(column)"
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

  public var description: String {
    "\(value)"
  }

  public static func auto(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column
  )
    -> BehaviorID
  {
    self.init(moduleFile: moduleFile, line: line, column: column, metadata: "auto")
  }

  @_spi(Implementation)
  public static func meta(
    moduleFile: String,
    line: Int,
    column: Int,
    meta: String
  )
    -> BehaviorID
  {
    self.init(moduleFile: moduleFile, line: line, column: column, metadata: meta)
  }

  public static func id(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    _ id: StaticString
  )
    -> BehaviorID
  {
    .init(value: "\(id)", debugInfo: "\(moduleFile):\(line):\(column)")
  }

  public static func == (lhs: BehaviorID, rhs: BehaviorID) -> Bool {
    lhs.value == rhs.value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(id)
  }

  // MARK: Internal

  static var invalid: BehaviorID {
    .init(value: "invalid", debugInfo: nil)
  }

  var id: String {
    value
  }

  #if DEBUG
  /// file, line, column information available in DEBUG builds only.
  let debugInfo: String?
  #else
  let debugInfo: String? = nil
  #endif
  // MARK: Private

  private let value: String

}
