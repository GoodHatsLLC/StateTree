import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - FieldDecoderTests

final class FieldDecoderTests: XCTestCase {

  func test_directDecoder() throws {
    let expected = DecoderExample(
      a: "qwert",
      b: 99,
      c: 100.1,
      d: false,
      e: .g,
      i: .init(
        j: 5,
        k: "yolo",
        l: .init(m: 22, n: false)
      ),
      o: .init(p: 12.3, q: true),
      r: URL(string: "https://example.com")!,
      s: nil,
      t: Set([1, 2, 3]),
      u: 18.3,
      v: [
        "hi": 5,
        "low": 6,
      ]
    )
    let payload = FieldDecoder(fields: [
      "a": "qwert",
      "b": 99,
      "c": 100.1,
      "d": false,
      "e": 2,
      "i": [
        "j": 5,
        "k": "yolo",
        "l": [
          "m": 22,
          "n": false,
        ] as [String: Any],
      ] as [String: Any],
      "o": [
        "p": 12.3,
        "q": true,
      ] as [String: Any],
      "r": "https://example.com",
      // "s": nil,
      "t": [1, 2, 3],
      "u": 18.3,
      "v": ["hi": 5, "low": 6],
    ])
    let decoded = try payload.decode(as: DecoderExample.self)
    XCTAssertEqual(expected, decoded)
  }
}

// MARK: FieldDecoderTests.DecoderExample

extension FieldDecoderTests {

  struct DecoderExample: Codable, Equatable {
    enum EnumType: Int, Codable, Equatable {
      case f = 1
      case g = 2
      case h = 3
    }

    struct StructType: Codable, Equatable {
      let j: Int
      let k: String
      let l: SubStruct
      struct SubStruct: Codable, Equatable {
        let m: Int
        let n: Bool
      }
    }

    class ClassType: Codable, Equatable {

      // MARK: Lifecycle

      init(p: Double, q: Bool) {
        self.p = p
        self.q = q
      }

      // MARK: Internal

      let p: Double
      let q: Bool

      static func == (lhs: ClassType, rhs: ClassType) -> Bool {
        lhs.p == rhs.p && lhs.q == rhs.q
      }

    }

    let a: String
    let b: Int
    let c: Double
    let d: Bool
    let e: EnumType
    let i: StructType
    let o: ClassType
    let r: URL
    let s: Int?
    let t: Set<Int>
    let u: Float
    let v: [String: Int]

  }
}
