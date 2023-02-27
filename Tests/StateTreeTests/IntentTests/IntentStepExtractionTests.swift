import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - IntentStepExtractionTests

final class IntentStepExtractionTests: XCTestCase {

  func test_nil_emptyIntent() throws {
    XCTAssertNil(Intent())
  }

  func test_intentStepExtraction() throws {
    var intent = try XCTUnwrap(
      Intent(
        Step(
          name: "step1",
          fields: ["fstr": "A Field"]
        ),
        Step(
          name: "step2",
          fields: ["fint": 123]
        ),
        Step(
          name: "step3",
          fields: ["fbool": false]
        ),
        Step4(fopt: nil),
        Step1(fstr: "Another Field")
      )
    )

    XCTAssertEqual(
      try intent.head.decode(as: Step1.self),
      Step1(fstr: "A Field")
    )
    intent = try XCTUnwrap(intent.tail)
    XCTAssertEqual(
      try intent.head.decode(as: Step2.self),
      Step2(fint: 123)
    )
    intent = try XCTUnwrap(intent.tail)
    XCTAssertEqual(
      try intent.head.decode(as: Step3.self),
      Step3(fbool: false)
    )
    intent = try XCTUnwrap(intent.tail)
    XCTAssertEqual(
      try intent.head.decode(as: Step4.self),
      Step4(fopt: nil)
    )
    intent = try XCTUnwrap(intent.tail)
    XCTAssertEqual(
      try intent.head.decode(as: Step1.self),
      Step1(fstr: "Another Field")
    )
    XCTAssertNil(intent.tail)
  }
}

extension IntentStepExtractionTests {

  struct Step1: IntentStep, Equatable {
    static let name = "step1"
    let fstr: String
  }

  struct Step2: IntentStep, Equatable {
    static let name = "step2"
    let fint: Int
  }

  struct Step3: IntentStep, Equatable {
    static let name = "step3"
    let fbool: Bool
  }

  struct Step4: IntentStep, Equatable {
    static let name = "step4"
    let fopt: Bool?
  }

}
