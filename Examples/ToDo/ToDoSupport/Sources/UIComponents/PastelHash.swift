import CryptoKit
import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

// MARK: - Pastel

public enum Pastel {

  static func hash(from item: some Hashable) -> Color {
    let hash = shaHex(value: String(describing: item))
    let hexPrefix = String(
      hash.prefix(
        upTo: String.Index(
          utf16Offset: 8,
          in: hash
        )
      )
    )
    var rgbValue: UInt64 = 0

    Scanner(string: hexPrefix)
      .scanHexInt64(&rgbValue)

    let rgb = Color(
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0
    )

    let pastelHue = rgb.hsba.hue
    let pastelSaturation = 0.2 + (rgb.hsba.saturation * 0.35)
    let pastelBrightness = 0.7 + (rgb.hsba.brightness * 0.3)

    return Color(
      hue: pastelHue,
      saturation: pastelSaturation,
      brightness: pastelBrightness
    )
  }

  static func shaHex(value: String) -> String {
    var hash = SHA256()
    hash.update(
      data: value.data(using: .utf8) ?? Data()
    )
    return
      hash
      .finalize()
      .hexStr
  }

}

extension Digest {
  var bytes: [UInt8] { Array(makeIterator()) }
  var data: Data { Data(bytes) }

  var hexStr: String {
    bytes.map { String(format: "%02X", $0) }.joined()
  }
}

extension Color {
  var hsba: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
    #if canImport(UIKit)
      typealias NativeColor = UIColor
    #elseif canImport(AppKit)
      typealias NativeColor = NSColor
    #endif

    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    NativeColor(self)
      .getHue(&h, saturation: &s, brightness: &b, alpha: &a)

    return (h, s, b, a)
  }
}
