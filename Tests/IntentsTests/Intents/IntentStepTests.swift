import Intents
import XCTest

// MARK: - IntentStepTests

final class IntentStepTests: XCTestCase {
//
//  func test_intentStep_decoding() throws {
//    let expected = FlatIntent(payload: "somepayload")
//    let step = try Step(name: "myintent", fields: ["payload": "somepayload"])
//    let decoded = try step.decode(as: FlatIntent.self)
//    XCTAssertEqual(expected, decoded)
//  }
//
//  func test_nestingIntentStep_decoding() throws {
//    let expected = NestedIntent(
//      subStruct: .init(
//        field1: true,
//        field2: 22,
//        field3: "333"
//      ),
//      loneField: 44.44,
//      subEnum: .one
//    )
//    let step = try Step(
//      name: "typenesting",
//      fields: [
//        "subStruct": [
//          "field1": true,
//          "field2": 22,
//          "field3": "333",
//        ] as [String: Any],
//        "loneField": 44.44,
//        "subEnum": "one",
//      ]
//    )
//    let decoded = try step.decode(as: NestedIntent.self)
//    XCTAssertEqual(expected, decoded)
//  }
//
//  func test_intentStep_decoding_failsByName() throws {
//    let step = try Step(name: "otherintent", fields: ["payload": "somepayload"])
//    XCTAssertThrowsError(
//      try step.decode(as: FlatIntent.self)
//    )
//  }
//
//  func test_intentStep_decoding_failsByFields() throws {
//    let step = try Step(name: "myintent", fields: ["playado": "somepayload"])
//    XCTAssertThrowsError(
//      try step.decode(as: FlatIntent.self)
//    )
//  }
}

extension IntentStepTests {

  struct FlatIntent: StepPayload {
    static let name = "myintent"
    let payload: String
  }

  struct NestedIntent: StepPayload {

    static let name = "typenesting"

    struct SubStruct: Codable, Hashable {
      let field1: Bool
      let field2: Int
      let field3: String
    }

    enum SubEnum: String, Codable {
      case one
      case two
    }

    let subStruct: SubStruct
    let loneField: Double
    let subEnum: SubEnum

  }

}
