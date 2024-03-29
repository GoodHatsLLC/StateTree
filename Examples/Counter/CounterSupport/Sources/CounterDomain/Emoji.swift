import UIKit

/// A utility which hashes values into an emoji representation.
public struct Emoji: Hashable {

  // MARK: Lifecycle

  public init?(unicodeValue: Int) {
    let emojiUnicode = Self.ranges
      .reduce(Int?(nil)) { value, range in
        if let value {
          return value
        }
        if range.contains(unicodeValue) {
          return unicodeValue
        }
        return nil
      }
    if let scalar = emojiUnicode.flatMap({ UnicodeScalar($0) }) {
      self.value = scalar
    } else {
      return nil
    }
  }

  // MARK: Public

  public var string: String {
    "\(value)"
  }

  public static func hash(of item: AnyHashable) -> Emoji {
    let hash = item.hashValue
    let emojiCount = ranges.map(\.count).reduce(0, +)
    let index = max(hash, -hash) % emojiCount
    return Emoji.index(index)!
  }

  public static func index(_ offset: Int) -> Emoji? {
    var offset = offset
    var emoji: Emoji?
    for range in ranges {
      if offset < range.count {
        let index = range.index(range.startIndex, offsetBy: offset)
        let codePoint = range[index]
        emoji = Emoji(unicodeValue: codePoint)
        break
      }
      offset -= range.count
    }
    return emoji
  }

  public func image(size width: Double = 40) -> UIImage {
    let size = CGSize(width: width, height: width)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    UIColor.clear.set()
    let nsString = (string as NSString)
    let font = UIFont.systemFont(ofSize: width * 0.75)
    let stringAttributes = [NSAttributedString.Key.font: font]
    let rect = CGRect(origin: .zero, size: .init(width: width, height: width))
    UIRectFill(rect)
    nsString.draw(
      in: rect,
      withAttributes: stringAttributes
    )
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }

  // MARK: Internal

  static let ranges = [
    0x1F600 ... 0x1F636,
    0x1F645 ... 0x1F64F,
    0x1F910 ... 0x1F91F,
    0x1F30D ... 0x1F52D,
  ]

  // MARK: Private

  private let value: Unicode.Scalar
}
