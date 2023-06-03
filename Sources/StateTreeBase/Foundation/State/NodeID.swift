import Disposable
import Foundation
import Intents
import Utilities

// MARK: - NodeID

/// The runtime identifier  representing a ``Node``.
///
/// String serialised `NodeIDs` are formatted as `<UUID>`
public struct NodeID: TreeState, LosslessStringConvertible, Comparable {

  // MARK: Lifecycle

  /// Create a `NodeID` from its `String` serialised representation:`<UUID>`
  public init?(_ description: String) {
    guard let uuid = UUID(uuidString: description)
    else {
      return nil
    }
    self.uuid = uuid
  }

  public init() {
    self.uuid = Self.makeUUID()
  }

  init(uuid: UUID = Self.makeUUID()) {
    self.uuid = uuid
  }

  /// Decode a `NodeID` from a serialised representation.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let str = try container.decode(String.self)
    guard let nodeID = NodeID(str)
    else {
      throw NodeIDDecodingError()
    }
    self = nodeID
  }

  // MARK: Public

  /// The `String` serialised NodeID
  public var description: String {
    uuid.uuidString
  }

  public static func < (lhs: NodeID, rhs: NodeID) -> Bool {
    withUnsafeBytes(of: lhs.uuid.uuid) { lhs in
      withUnsafeBytes(of: rhs.uuid.uuid) { rhs in
        lhs.lexicographicallyPrecedes(rhs)
      }
    }
  }

  /// Encode a `NodeID` to a serialised representation.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }

  #if DEBUG
  @_spi(Implementation)
  public static func incrementForTesting() -> AutoDisposable {
    incrementingForTesting.value = 1
    return .init {
      incrementingForTesting.value = nil
    }
  }

  private static let incrementingForTesting = Locked<Int?>(nil)

  private static func makeUUID() -> UUID {
    let num = Self.incrementingForTesting.withLock { num in
      let curr = num
      num = num.map { $0 + 1 }
      return curr
    }
    return num.map { UUID.num($0) } ?? UUID()
  }
  #else
  private static func makeUUID() -> UUID { UUID() }
  #endif
  // MARK: Internal

  /// A custom invalid `NodeID` which should never be present in serialised output.
  static let invalid = NodeID(uuid: .fifteens)

  /// A custom `NodeID` indicating a reference to the StateTree system itself.
  static let system = NodeID(uuid: .zeros)

  /// A custom `NodeID` identifying the root node.
  static let root = NodeID(uuid: .ones)

  let uuid: UUID

}

// MARK: - NodeIDDecodingError

class NodeIDDecodingError: Error { }

extension UUID {

  fileprivate static let zeros: UUID = .init(uuidString: "00000000-0000-0000-0000-000000000000")!
  fileprivate static let ones: UUID = .init(uuidString: "00000000-1111-1111-1111-111111111111")!
  fileprivate static let fifteens: UUID = .init(uuidString: "00000000-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!

  #if DEBUG
  /// A custom incrementing UUID value used only in testing
  fileprivate static func num(_ num: Int) -> UUID {
    let numStr = String(num)
    let padded = String(repeating: "0", count: 12 - numStr.count) + numStr
    return UUID(
      uuidString: "00000000-FFFF-0000-0000-\(padded)"
    ) ?? .fifteens
  }
  #endif
}
