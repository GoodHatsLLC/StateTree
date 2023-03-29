import Foundation
import TreeState

// MARK: - CUID

/// CUID — Custom User Identity
/// The `CUID` contains a ``Node``'s defined `id` if it is `Identifiable`
public struct CUID: LosslessStringConvertible, TreeState {
  public init?(_ description: String) {
    guard !description.isEmpty
    else {
      return nil
    }
    self.description = description
  }

  public let description: String
  public init?(_ description: String?) {
    guard
      let description,
      !description.isEmpty
    else {
      return nil
    }
    self.description = description
  }
}

@_spi(Implementation)
extension CUID {
  public static let invalid = CUID("❌")!
  public static let system = CUID("⚡️")!
  public static let root = CUID("🌳")!
}