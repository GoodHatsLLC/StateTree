import SwiftUI

// MARK: - Spacing

public enum Spacing {
  public typealias Unit = Double
  public static var unitSize: Double = 8
}

extension BinaryInteger {
  public var su: Spacing.Unit { Double(self) * Spacing.unitSize }
}

extension BinaryFloatingPoint {
  public var su: Spacing.Unit { Double(self) * Spacing.unitSize }
}
