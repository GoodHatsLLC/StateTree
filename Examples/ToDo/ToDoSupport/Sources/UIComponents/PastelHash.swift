import CryptoKit
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Pastel

public enum Pastel {

  static func hash(from item: some Hashable) -> Colour {
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

    let rgb = Colour(
      red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: Double(rgbValue & 0x0000FF) / 255.0
    )

    let pastelHue = rgb.hsba.hue
    let pastelSaturation = 0.2 + (rgb.hsba.saturation * 0.35)
    let pastelBrightness = 0.7 + (rgb.hsba.brightness * 0.3)

    return NativeColor(
      hue: pastelHue,
      saturation: pastelSaturation,
      brightness: pastelBrightness,
      alpha: rgb.opacity
    ).colour
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
    bytes.map { String(format: "%02x", $0) }.joined()
  }
}
