// MARK: - Colour

public struct Colour {

  public let red: Double
  public let green: Double
  public let blue: Double
  public let opacity: Double

  public init(
    red: Double,
    green: Double,
    blue: Double,
    opacity: Double = 1.0
  ) {
    self.red = red
    self.green = green
    self.blue = blue
    self.opacity = opacity
  }
}

#if canImport(UIKit)
import UIColor
public typealias NativeColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias NativeColor = NSColor
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

extension Colour {

  // MARK: Lifecycle

  public init(native: NativeColor) {
    self.red = native.redComponent
    self.green = native.greenComponent
    self.blue = native.blueComponent
    self.opacity = native.alphaComponent
  }

  // MARK: Public

  public static var clear: Colour {
    .init(red: 1, green: 1, blue: 1, opacity: 0)
  }

  #if canImport(SwiftUI)
  public var swiftUI: Color {
    .init(red: red, green: green, blue: blue, opacity: opacity)
  }
  #endif

  public var hsba: (hue: Double, saturation: Double, brightness: Double, opacity: Double) {
    #if canImport(UIKit)
    var h: Double = 0
    var s: Double = 0
    var b: Double = 0
    var a: Double = 0
    native.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    return (h, s, b, a)
    #elseif canImport(AppKit)
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    native.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

    return (h, s, b, a)
    #endif
  }

  public var native: NativeColor {
    .init(red: red, green: green, blue: blue, alpha: opacity)
  }

}

extension NativeColor {
  public var colour: Colour {
    .init(
      red: redComponent,
      green: greenComponent,
      blue: blueComponent,
      opacity: alphaComponent
    )
  }
}
