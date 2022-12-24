import Foundation

extension UUID {
  public static var null: UUID {
    UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
  }

  public static var max: UUID {
    UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!
  }

  public var short: String {
    uuidString
      .split(separator: "-")
      .compactMap { group in
        """
        \(
                    (group.first.map { "\($0)" } ?? "_") +
                        (group.last.map { "\($0)" } ?? "_")
                )
        """
      }
      .joined()
  }
}
