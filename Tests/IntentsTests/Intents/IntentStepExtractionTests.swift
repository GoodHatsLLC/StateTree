import Intents
import XCTest

// MARK: - IntentStepExtractionTests

final class IntentStepExtractionTests: XCTestCase {

  func test_intentStepExtraction() throws {
    var intent = try XCTUnwrap(
      Intent(
        Step1(fstr: "A Field"),
        Step2(fint: 123),
        Step3(fbool: false),
        Step4(fopt: nil),
        Step1(fstr: "Another Field")
      )
    )

    XCTAssertEqual(
      try intent.head?.getPayload(as: Step1.self),
      Step1(fstr: "A Field")
    )
    intent = try XCTUnwrap(intent.tail)
    XCTAssertEqual(
      try intent.head?.getPayload(as: Step2.self),
      Step2(fint: 123)
    )
    intent = try XCTUnwrap(intent.tail)
    XCTAssertEqual(
      try intent.head?.getPayload(as: Step3.self),
      Step3(fbool: false)
    )
    intent = try XCTUnwrap(intent.tail)
    XCTAssertEqual(
      try intent.head?.getPayload(as: Step4.self),
      Step4(fopt: nil)
    )
    intent = try XCTUnwrap(intent.tail)
    XCTAssertEqual(
      try intent.head?.getPayload(as: Step1.self),
      Step1(fstr: "Another Field")
    )
    XCTAssertNil(intent.tail)
  }
}

extension IntentStepExtractionTests {

  struct Step1: StepPayload {
    static let name = "step1"
    let fstr: String
  }

  struct Step2: StepPayload {
    static let name = "step2"
    let fint: Int
  }

  struct Step3: StepPayload {
    static let name = "step3"
    let fbool: Bool
  }

  struct Step4: StepPayload {
    static let name = "step4"
    let fopt: Bool?
  }

}
