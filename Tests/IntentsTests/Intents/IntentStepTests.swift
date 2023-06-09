import Intents
import XCTest

// MARK: - IntentStepTests

final class IntentStepTests: XCTestCase {

  func test_nestingIntentStep_decoding() throws {
    let expected = NestedIntent(
      subStruct: .init(
        field1: true,
        field2: 22,
        field3: "333"
      ),
      loneField: 44.44,
      subEnum: .one
    )
    let step = Step(
      NestedIntent(
        subStruct: .init(
          field1: true,
          field2: 22,
          field3: "333"
        ),
        loneField: 44.44,
        subEnum: .one
      )
    )
    let decoded = try step.getPayload(as: NestedIntent.self)
    XCTAssertEqual(expected, decoded)
  }

  func test_intentStep_decoding_failsB() throws {
    let step = Step(SomeIntent(payload: "hi"))
    XCTAssertThrowsError(
      try step.getPayload(as: FlatIntent.self)
    )
  }
}

extension IntentStepTests {

  struct FlatIntent: StepPayload {
    static let name = "myintent"
    let payload: String
  }

  struct SomeIntent: StepPayload {
    static let name = "otherintent"
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
