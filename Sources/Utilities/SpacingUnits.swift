#if canImport(SwiftUI)
import SwiftUI

// MARK: - Spacing

public enum Spacing {
  public typealias Unit = Double
  public static var unit: Double = 8
}

extension BinaryInteger {
  public var su: Spacing.Unit { Spacing.unit }
}

extension BinaryFloatingPoint {
  public var su: Spacing.Unit { Spacing.unit }
}
#endif
