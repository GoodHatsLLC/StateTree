import SwiftUI

// MARK: - Spacing

public enum Spacing {
  public typealias Unit = Double
  public static var unit: Double = 8
}

extension BinaryInteger {
  var su: Spacing.Unit { Spacing.unit }
}

extension BinaryFloatingPoint {
  var su: Spacing.Unit { Spacing.unit }
}
