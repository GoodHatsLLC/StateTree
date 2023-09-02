import SwiftUI
#if canImport(UIKit)
import UIKit
public typealias NativeColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias NativeColor = NSColor
#endif

extension NativeColor {
  public var rgba: (red: Double, green: Double, blue: Double, alpha: Double) {
    var redComponent: CGFloat = 0
    var greenComponent: CGFloat = 0
    var blueComponent: CGFloat = 0
    var alphaComponent: CGFloat = 0
    getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha: &alphaComponent)
    return (
      red: redComponent,
      green: greenComponent,
      blue: blueComponent,
      alpha: alphaComponent
    )
  }

  public var rgbaData: (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
    let uInt8max = CGFloat(UInt8.max)
    var redComponent: CGFloat = 0
    var greenComponent: CGFloat = 0
    var blueComponent: CGFloat = 0
    var alphaComponent: CGFloat = 0
    getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha: &alphaComponent)
    return (
      red: UInt8(redComponent * uInt8max),
      green: UInt8(greenComponent * uInt8max),
      blue: UInt8(blueComponent * uInt8max),
      alpha: UInt8(alphaComponent * uInt8max)
    )
  }

  public var hsba: (hue: Double, saturation: Double, brightness: Double, alpha: Double) {
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    return (hue: h, saturation: s, brightness: b, alpha: a)
  }

  public var cmyka: (
    cyan: Double,
    magenta: Double,
    yellow: Double,
    black: Double,
    alpha: Double
  ) {
    #if canImport(UIKit)
    let (r, g, b, a) = rgba
    let k = 1.0 - max(r, g, b)
    var c = (1.0 - r - k) / (1.0 - k)
    var m = (1.0 - g - k) / (1.0 - k)
    var y = (1.0 - b - k) / (1.0 - k)
    if c.isNaN {
      c = 0.0
    }
    if m.isNaN {
      m = 0.0
    }
    if y.isNaN {
      y = 0.0
    }
    return (cyan: c, magenta: m, yellow: y, black: k, alpha: a)
    #elseif canImport(AppKit)
    var c: CGFloat = 0
    var m: CGFloat = 0
    var y: CGFloat = 0
    var k: CGFloat = 0
    var a: CGFloat = 0
    getCyan(&c, magenta: &m, yellow: &y, black: &k, alpha: &a)
    return (cyan: c, magenta: m, yellow: y, black: k, alpha: a)
    #endif
  }
}

// MARK: - Colour

public struct Colour: Hashable, Codable {

  // MARK: Lifecycle

  public init(from decoder: any Decoder) throws {
    var container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    guard let colour = Colour(hex: string)
    else {
      throw DecodingError.dataCorrupted(.init(
        codingPath: [],
        debugDescription: "\(string) was invalid"
      ))
    }
    self = colour
  }

  public init(_ color: NativeColor) {
    let data = color.rgbaData
    self.red = data.red
    self.green = data.green
    self.blue = data.blue
    self.alpha = data.alpha
  }

  public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  public init?(hex: String) {
    let max = UInt8.max
    let r, g, b, a: UInt8
    var hex = hex.lowercased()
    if hex.hasPrefix("#") {
      hex.removeFirst()
    }
    let regex = /[a-f0-9]*/
    guard
      let match = hex.wholeMatch(of: regex),
      !match.isEmpty
    else {
      return nil
    }
    if hex.count == 6 {
      let r0 = hex.index(hex.startIndex, offsetBy: 0)
      let r1 = hex.index(hex.startIndex, offsetBy: 2)
      let g0 = hex.index(hex.startIndex, offsetBy: 2)
      let g1 = hex.index(hex.startIndex, offsetBy: 4)
      let b0 = hex.index(hex.startIndex, offsetBy: 4)
      let b1 = hex.index(hex.startIndex, offsetBy: 6)
      guard
        let red = UInt8(hex[r0 ..< r1], radix: 16),
        let green = UInt8(hex[g0 ..< g1], radix: 16),
        let blue = UInt8(hex[b0 ..< b1], radix: 16)
      else {
        return nil
      }
      r = red
      g = green
      b = blue
      a = max
      if r > max || g > max || b > max {
        return nil
      }

    } else if hex.count == 8 {
      let r0 = hex.index(hex.startIndex, offsetBy: 0)
      let r1 = hex.index(hex.startIndex, offsetBy: 2)
      let g0 = hex.index(hex.startIndex, offsetBy: 2)
      let g1 = hex.index(hex.startIndex, offsetBy: 4)
      let b0 = hex.index(hex.startIndex, offsetBy: 4)
      let b1 = hex.index(hex.startIndex, offsetBy: 6)
      let a0 = hex.index(hex.startIndex, offsetBy: 6)
      let a1 = hex.index(hex.startIndex, offsetBy: 8)
      guard
        let red = UInt8(hex[r0 ..< r1], radix: 16),
        let green = UInt8(hex[g0 ..< g1], radix: 16),
        let blue = UInt8(hex[b0 ..< b1], radix: 16),
        let alpha = UInt8(hex[a0 ..< a1], radix: 16)
      else {
        return nil
      }
      r = red
      g = green
      b = blue
      a = alpha
      if r > max || g > max || b > max || a > max {
        return nil
      }
    } else {
      return nil
    }
    self = .init(red: r, green: g, blue: b, alpha: a)
  }

  // MARK: Public

  public static var red: Colour { .init(.red) }
  public static var blue: Colour { .init(.blue) }
  public static var yellow: Colour { .init(.yellow) }
  public static var cyan: Colour { .init(.cyan) }
  public static var green: Colour { .init(.green) }
  public static var orange: Colour { .init(.orange) }
  public static var purple: Colour { .init(.purple) }

  public var native: NativeColor {
    get {
      let max = CGFloat(UInt8.max)
      return NativeColor(
        deviceRed: CGFloat(red) / max,
        green: CGFloat(green) / max,
        blue: CGFloat(blue) / max,
        alpha: CGFloat(alpha) / max
      )
    }
    set {
      self = .init(newValue)
    }
  }

  public var swiftUI: Color {
    get {
      .init(native)
    }
    set {
      self = .init(NativeColor(newValue))
    }
  }

  public var hexString: String {
    [red, green, blue, alpha]
      .map { channelProportion in
        String(
          format: "%02lx",
          Int(channelProportion)
        )
      }
      .reduce("#", +)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(hexString)
  }

  // MARK: Internal

  let red: UInt8
  let green: UInt8
  let blue: UInt8
  let alpha: UInt8

}
