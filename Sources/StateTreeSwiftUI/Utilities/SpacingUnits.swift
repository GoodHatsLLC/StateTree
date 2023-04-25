import SwiftUI

// MARK: - Spacing

enum Spacing {
  typealias Unit = Double
  static var unit: Double = 8
}

extension BinaryInteger {
  var su: Spacing.Unit { Spacing.unit }
}

extension BinaryFloatingPoint {
  var su: Spacing.Unit { Spacing.unit }
}
