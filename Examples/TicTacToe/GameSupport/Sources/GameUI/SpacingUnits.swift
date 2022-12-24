import SwiftUI

// MARK: - Spacing

public enum Spacing {
  public typealias Unit = CGFloat
  public static var unitSize: CGFloat = 8
}

extension BinaryInteger {
  public var su: Spacing.Unit { Spacing.unitSize }
}

extension BinaryFloatingPoint {
  public var su: Spacing.Unit { Spacing.unitSize }
}
