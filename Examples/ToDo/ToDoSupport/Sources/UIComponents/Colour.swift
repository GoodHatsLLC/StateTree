// MARK: - ColourConvertible

/// Convertible to ``Colour``
public protocol ColourConvertible {
  var colour: Colour { get }
}

// MARK: - Colour

/// Platform independent, correctly spelled, colours.
public struct Colour: Hashable, Codable, Sendable, LosslessStringConvertible {

  // MARK: Lifecycle

  public init<Intensity: BinaryFloatingPoint>(
    red: Intensity,
    green: Intensity,
    blue: Intensity,
    alpha: Intensity = 1.0
  ) {
    self.storage = .init(
      red: red.clamped,
      green: green.clamped,
      blue: blue.clamped,
      alpha: alpha.clamped
    )
  }

  public init(_ convertible: some ColourConvertible) {
    self = convertible.colour
  }

  public init?(_ description: String) {
    guard let this = RGBA(hex: description).map({ Colour($0) })
    else {
      return nil
    }
    self = this
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let hex = try container.decode(String.self)
    guard let rgba = RGBA(hex: hex)
    else {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: [],
          debugDescription: "Invalid RGBA hex string: \(hex)"
        )
      )
    }
    self = rgba.colour
  }

  // MARK: Public

  public var description: String {
    rgba.hexString
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rgba.hexString)
  }

  // MARK: Private

  private let storage: RGBA

}

// MARK: - native colour type bridging

#if canImport(UIKit)
import UIKit
public typealias NativeColor = UIColor
extension Colour {

  // MARK: Lifecycle

  public init(_ nativeColour: NativeColor) {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    nativeColour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    self.init(
      red: red,
      green: green,
      blue: blue,
      alpha: alpha
    )
  }

  // MARK: Public

  public var uiColor: UIColor { nativeColor }

  // MARK: Internal

  var nativeColor: NativeColor {
    NativeColor(red: storage.r, green: storage.g, blue: storage.b, alpha: storage.a)
  }
}

#elseif canImport(AppKit)
import AppKit
public typealias NativeColor = NSColor
extension Colour {

  // MARK: Lifecycle

  public init(_ nativeColour: NativeColor) {
    self.init(
      red: nativeColour.redComponent,
      green: nativeColour.greenComponent,
      blue: nativeColour.blueComponent,
      alpha: nativeColour.alphaComponent
    )
  }

  // MARK: Public

  public var nsColor: NSColor { nativeColor }

  // MARK: Internal

  var nativeColor: NativeColor {
    NativeColor(red: storage.r, green: storage.g, blue: storage.b, alpha: storage.a)
  }
}
#endif

#if canImport(SwiftUI)
import SwiftUI
extension Colour {

  // MARK: Lifecycle

  public init(_ color: Color) {
    self.init(NativeColor(color))
  }

  // MARK: Public

  public var swiftUI: Color {
    get {
      Color(nativeColor)
    }
    set {
      self = .init(NativeColor(newValue))
    }
  }
}
#endif

// MARK: - NativeColourConvertible

private protocol NativeColourConvertible {
  var nativeColor: NativeColor { get }
}

// MARK: - colour representations
extension Colour {
  public struct RGBA: Hashable, Codable, Sendable, LosslessStringConvertible, ColourConvertible,
    NativeColourConvertible
  {

    // MARK: Lifecycle

    public init(RGBAHex: UInt32) {
      let red = Double((RGBAHex & 0xFF00_0000) >> 24) / 255.0
      let green = Double((RGBAHex & 0xFF0000) >> 16) / 255.0
      let blue = Double((RGBAHex & 0xFF00) >> 8) / 255.0
      let alpha = Double((RGBAHex & 0xFF) >> 0) / 255.0
      self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    public init(RGBHex: UInt32, alpha: Double = 1.0) {
      let red = Double((RGBHex & 0xFF0000) >> 16) / 255.0
      let green = Double((RGBHex & 0xFF00) >> 8) / 255.0
      let blue = Double((RGBHex & 0xFF) >> 0) / 255.0
      self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    public init?(hex: String) {
      let r, g, b, a: Double
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
          let red = UInt8(hex[r0 ..< r1], radix: 16).map(Double.init),
          let green = UInt8(hex[g0 ..< g1], radix: 16).map(Double.init),
          let blue = UInt8(hex[b0 ..< b1], radix: 16).map(Double.init)
        else {
          return nil
        }
        r = red / 255.0
        g = green / 255.0
        b = blue / 255.0
        a = 1.0
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
          let red = UInt8(hex[r0 ..< r1], radix: 16).map(Double.init),
          let green = UInt8(hex[g0 ..< g1], radix: 16).map(Double.init),
          let blue = UInt8(hex[b0 ..< b1], radix: 16).map(Double.init),
          let alpha = UInt8(hex[a0 ..< a1], radix: 16).map(Double.init)
        else {
          return nil
        }
        r = red / 255.0
        g = green / 255.0
        b = blue / 255.0
        a = alpha / 255.0
      } else {
        return nil
      }
      self.init(red: r, green: g, blue: b, alpha: a)
    }

    public init?(_ description: String) {
      let regex = /RGBA\(([0-9\.])*\, ([0-9\.])*\, ([0-9\.])*\, ([0-9\.])*\)/
      guard
        let match = description.wholeMatch(of: regex),
        let red = match.output.1.flatMap({ Double($0) }),
        let green = match.output.2.flatMap({ Double($0) }),
        let blue = match.output.3.flatMap({ Double($0) }),
        let alpha = match.output.4.flatMap({ Double($0) })
      else {
        return nil
      }
      self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      let description = try container.decode(String.self)
      guard let this = RGBA(description)
      else {
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: [],
            debugDescription: "Invalid RGBA value: \(description)"
          )
        )
      }
      self = this
    }

    public init<Intensity: BinaryFloatingPoint>(
      red: Intensity,
      green: Intensity,
      blue: Intensity,
      alpha: Intensity
    ) {
      self.red = red.clamped
      self.blue = blue.clamped
      self.green = green.clamped
      self.alpha = alpha.clamped
    }

    // MARK: Public

    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public var hexString: String {
      [red, green, blue, alpha]
        .map { channelProportion in
          String(
            format: "%02lx",
            Int(round(channelProportion * 255.0))
          )
        }
        .reduce("#", +)
    }

    public var colour: Colour {
      .init(red: red, green: green, blue: blue, alpha: alpha)
    }

    public var description: String {
      "RGBA(\(red.decimal), \(green.decimal), \(blue.decimal), \(alpha.decimal))"
    }

    public var r: Double { red }
    public var g: Double { green }
    public var b: Double { blue }
    public var a: Double { alpha }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(description)
    }

    // MARK: Internal

    var nativeColor: NativeColor {
      NativeColor(red: red, green: green, blue: blue, alpha: alpha)
    }

  }

  public struct CMYKA: Hashable, Codable, Sendable, LosslessStringConvertible, ColourConvertible,
    NativeColourConvertible
  {

    // MARK: Lifecycle

    public init?(_ description: String) {
      let regex = /CMYKA\(([0-9\.])*\, ([0-9\.])*\, ([0-9\.])*\, ([0-9\.])*\, ([0-9\.])*\)/
      guard
        let match = description.wholeMatch(of: regex),
        let cyan = match.output.1.flatMap({ Double($0) }),
        let magenta = match.output.2.flatMap({ Double($0) }),
        let yellow = match.output.3.flatMap({ Double($0) }),
        let black = match.output.4.flatMap({ Double($0) }),
        let alpha = match.output.5.flatMap({ Double($0) })
      else {
        return nil
      }
      self.init(cyan: cyan, magenta: magenta, yellow: yellow, black: black, alpha: alpha)
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      let description = try container.decode(String.self)
      guard let this = CMYKA(description)
      else {
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: [],
            debugDescription: "Invalid CMYKA value: \(description)"
          )
        )
      }
      self = this
    }

    public init<Intensity: BinaryFloatingPoint>(
      cyan: Intensity,
      magenta: Intensity,
      yellow: Intensity,
      black: Intensity,
      alpha: Intensity
    ) {
      self.cyan = cyan.clamped
      self.magenta = magenta.clamped
      self.yellow = yellow.clamped
      self.black = black.clamped
      self.alpha = alpha.clamped
    }

    // MARK: Public

    public let cyan: Double
    public let magenta: Double
    public let yellow: Double
    public let black: Double
    public let alpha: Double

    public var colour: Colour {
      Colour(nativeColor)
    }

    public var description: String {
      "CMYKA(\(cyan.decimal), \(magenta.decimal), \(yellow.decimal), \(black.decimal), \(alpha.decimal))"
    }

    public var c: Double { cyan }
    public var m: Double { magenta }
    public var y: Double { yellow }
    public var k: Double { black }
    public var a: Double { alpha }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(description)
    }

    // MARK: Internal

    var nativeColor: NativeColor {
      let rgba = rgba
      return NativeColor(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
    }

    var rgba: RGBA {
      let r = (1.0 - cyan) * (1.0 - black)
      let g = (1.0 - magenta) * (1.0 - black)
      let b = (1.0 - yellow) * (1.0 - black)
      return .init(red: r, green: g, blue: b, alpha: alpha)
    }

  }

  public struct HSBA: Hashable, Codable, Sendable, LosslessStringConvertible, ColourConvertible,
    NativeColourConvertible
  {

    // MARK: Lifecycle

    public init?(_ description: String) {
      let regex = /HSBA\(([0-9\.])*\, ([0-9\.])*\, ([0-9\.])*\, ([0-9\.])*\)/
      guard
        let match = description.wholeMatch(of: regex),
        let hue = match.output.1.flatMap({ Double($0) }),
        let saturation = match.output.2.flatMap({ Double($0) }),
        let brightness = match.output.3.flatMap({ Double($0) }),
        let alpha = match.output.4.flatMap({ Double($0) })
      else {
        return nil
      }
      self.init(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      let description = try container.decode(String.self)
      guard let this = HSBA(description)
      else {
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: [],
            debugDescription: "Invalid HSBA value: \(description)"
          )
        )
      }
      self = this
    }

    public init<Intensity: BinaryFloatingPoint>(
      hue: Intensity,
      saturation: Intensity,
      brightness: Intensity,
      alpha: Intensity
    ) {
      self.hue = hue.clamped
      self.saturation = saturation.clamped
      self.brightness = brightness.clamped
      self.alpha = alpha.clamped
    }

    // MARK: Public

    public let hue: Double
    public let saturation: Double
    public let brightness: Double
    public let alpha: Double

    public var colour: Colour {
      Colour(nativeColor)
    }

    public var description: String {
      "HSBA(\(hue.decimal), \(saturation.decimal), \(brightness.decimal), \(alpha.decimal))"
    }

    public var h: Double { hue }
    public var s: Double { saturation }
    public var b: Double { brightness }
    public var a: Double { alpha }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(description)
    }

    // MARK: Internal

    var nativeColor: NativeColor {
      NativeColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

  }
}

extension Colour {

  /// Red, Green, Blue, Alpha
  public var rgba: RGBA {
    storage
  }

  #if canImport(UIKit) || canImport(AppKit)
  /// Hue, Saturation, Brightness, Alpha
  public var hsba: HSBA {
    #if canImport(UIKit)
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    nativeColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    return HSBA(hue: h, saturation: s, brightness: b, alpha: a)
    #elseif canImport(AppKit)
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    nativeColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    return HSBA(hue: h, saturation: s, brightness: b, alpha: a)
    #endif
  }
  #endif

  #if canImport(UIKit) || canImport(AppKit)
  /// Cyan, Magenta, Black, Alpha
  public var cmyka: CMYKA {
    #if canImport(UIKit)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    nativeColor.getRed(&r, green: &g, blue: &b, alpha: &a)

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
    return CMYKA(cyan: c, magenta: m, yellow: y, black: k, alpha: a)
    #elseif canImport(AppKit)
    var c: CGFloat = 0
    var m: CGFloat = 0
    var y: CGFloat = 0
    var k: CGFloat = 0
    var a: CGFloat = 0
    nativeColor.getCyan(&c, magenta: &m, yellow: &y, black: &k, alpha: &a)

    return CMYKA(cyan: c, magenta: m, yellow: y, black: k, alpha: a)
    #endif
  }
  #endif
}

// MARK: - static colours
extension Colour {

  /// macOS light-mode ('Aqua') red.  (RGBA hex: `#ff3b2fff`)
  public static let red = Colour(#colorLiteral(red: 1.0, green: 0.233, blue: 0.186, alpha: 1.0))

  /// macOS light-mode ('Aqua') orange.  (RGBA hex: `#ff9500ff`)
  public static let orange = Colour(#colorLiteral(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0))

  /// macOS light-mode ('Aqua') yellow.  (RGBA hex: `#ffcc02ff`)
  public static let yellow = Colour(#colorLiteral(red: 1.0, green: 0.8, blue: 0.008, alpha: 1.0))

  /// macOS light-mode ('Aqua') green.  (RGBA hex: `#27cd41ff`)
  public static let green = Colour(#colorLiteral(red: 0.153, green: 0.804, blue: 0.255, alpha: 1.0))

  /// macOS light-mode ('Aqua') mint.  (RGBA hex: `#03c7beff`)
  public static let mint = Colour(#colorLiteral(red: 0.012, green: 0.78, blue: 0.745, alpha: 1.0))

  /// macOS light-mode ('Aqua') teal.  (RGBA hex: `#59adc4ff`)
  public static let teal = Colour(#colorLiteral(red: 0.349, green: 0.678, blue: 0.769, alpha: 1.0))

  /// macOS light-mode ('Aqua') cyan.  (RGBA hex: `#54bef0ff`)
  public static let cyan = Colour(#colorLiteral(red: 0.329, green: 0.745, blue: 0.941, alpha: 1.0))

  /// macOS light-mode ('Aqua') blue.  (RGBA hex: `#007affff`)
  public static let blue = Colour(#colorLiteral(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0))

  /// macOS light-mode ('Aqua') indigo.  (RGBA hex: `#5856d5ff`)
  public static let indigo = Colour(#colorLiteral(red: 0.345, green: 0.337, blue: 0.835, alpha: 1.0))

  /// macOS light-mode ('Aqua') purple.  (RGBA hex: `#af52deff`)
  public static let purple = Colour(#colorLiteral(red: 0.686, green: 0.322, blue: 0.871, alpha: 1.0))

  /// macOS light-mode ('Aqua') pink.  (RGBA hex: `#ff2c55ff`)
  public static let pink = Colour(#colorLiteral(red: 1.0, green: 0.173, blue: 0.333, alpha: 1.0))

  /// Apple color picker magenta.  (RGBA hex: `#ff42ffff`)
  public static let magenta = Colour(#colorLiteral(red: 1, green: 0.2527923882, blue: 1, alpha: 1))

  /// macOS light-mode ('Aqua') brown.  (RGBA hex: `#a2845eff`)
  public static let brown = Colour(#colorLiteral(red: 0.635, green: 0.518, blue: 0.369, alpha: 1.0))

  /// macOS light-mode ('Aqua') grey.  (RGBA hex: `#8e8e93ff`)
  public static let grey = Colour(#colorLiteral(red: 0.557, green: 0.557, blue: 0.576, alpha: 1.0))

  /// macOS light-mode ('Aqua') white.  (RGBA hex: `#efefefff`)
  public static let white = Colour(#colorLiteral(red: 0.937, green: 0.937, blue: 0.937, alpha: 1.0))

  /// macOS light-mode ('Aqua') black.  (RGBA hex: `#000000ff`)
  public static let black = Colour(#colorLiteral(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))

  /// macOS light-mode ('Aqua') clear.  (RGBA hex: `#ffffff00`)
  public static let clear = Colour(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0))

}

// MARK: - private convenience extensions

extension BinaryFloatingPoint {
  fileprivate var clamped: Double { max(min(Double(self), 1.0), 0.0) }
}

extension Double {
  fileprivate var decimal: String {
    String(format: "%.3f", self)
  }
}
