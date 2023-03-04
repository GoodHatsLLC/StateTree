import Foundation

enum SimpleHash {

  static func hash(_ string: String) -> String {
    hash(bytes: string.flatMap(\.utf8))
  }

  static func hash(_ input: Data) -> String {
    hash(bytes: input.map { $0 })
  }

  static func hash(bytes: [UInt8]) -> String {
    var one: UInt32 = 0
    var two: UInt32 = 0
    for unit in bytes {
      let unit = UInt32(unit)
      one = (one + unit) % 65536
      two = (one + two) % 65536
    }
    let result = (two << 16) | one
    let shifts = [24, 16, 8, 0]
    let bytes = shifts.map { UInt8(truncatingIfNeeded: result >> $0) }
    return bytes.map { String(format: "%02x", $0) }.joined()
  }
}
