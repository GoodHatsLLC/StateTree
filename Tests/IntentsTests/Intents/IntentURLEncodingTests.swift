import Utilities
import XCTest
@testable import Intents

// MARK: - IntentURLEncodingTests

final class IntentURLEncodingTests: XCTestCase {

  func test_encoding() throws {
    let step1 = TestStep1(field1: "one", field2: "two", field3: "three")
    let step2 = TestStep2(field1: "|", field2: "/", field3: "abc")
    let step3 = TestStep3(field1: "aaa", field2: "bbb", field3: ":", ffour: 123)

    // steps/aaa1/field1=one&field2=two&field3=three/aaa2/field1=%7C&field2=%2F&field3=abc/aaa3/field2=bbb&field1=aaa&field3=:&ffour=123
    let payload = try Intent.urlString(with: [step1, step2, step3])
    let encodedString = try XCTUnwrap(payload.split(separator: "/", maxSplits: 1).last)
    let stepStrings = encodedString.split(separator: "/")
    XCTAssertEqual(stepStrings.count, 6)

    XCTAssertEqual(stepStrings[0], "aaa1")
    XCTAssertEqual(stepStrings[2], "aaa2")
    XCTAssertEqual(stepStrings[4], "aaa3")

    XCTAssertEqual(
      stepStrings[1].split(separator: "&").sorted().map { String($0) },
      [
        "field1=one",
        "field2=two",
        "field3=three",
      ]
    )
    XCTAssertEqual(
      stepStrings[3].split(separator: "&").sorted().map { String($0) },
      [
        "field1=%7C",
        "field2=%2F",
        "field3=abc",
      ]
    )
    XCTAssertEqual(
      stepStrings[5].split(separator: "&").sorted().map { String($0) },
      [
        "ffour=123",
        "field1=aaa",
        "field2=bbb",
        "field3=:",
      ]
    )
  }

  func test_decoding() throws {
    let step1 = TestStep1(field1: "one", field2: "two", field3: "three")
    let step2 = TestStep2(field1: "|", field2: "/", field3: "abc")
    let step3 = TestStep3(field1: "aaa", field2: "bbb", field3: ":", ffour: 123)
    let intent = Intent(step1, step2, step3)
    let encodedString = try Intent.urlString(with: [step1, step2, step3])
    let decoded = try Intent.from(urlEncoded: encodedString)
    XCTAssertEqual(
      try intent?.head?.getPayload(as: TestStep1.self),
      try decoded?.head?.getPayload(as: TestStep1.self)
    )
    XCTAssertEqual(
      try intent?.tail?.head?.getPayload(as: TestStep2.self),
      try decoded?.tail?.head?.getPayload(as: TestStep2.self)
    )
    XCTAssertEqual(
      try intent?.tail?.tail?.head?.getPayload(as: TestStep3.self),
      try decoded?.tail?.tail?.head?.getPayload(as: TestStep3.self)
    )
    XCTAssertNotNil(try intent?.tail?.tail?.head?.getPayload(as: TestStep3.self))
  }

  func testPrerequisite_step_encodingDecoding() throws {
    let step1 = TestStep1(field1: "one", field2: "two", field3: "three")
    let step2 = TestStep2(field1: "|", field2: "/", field3: "abc")
    let step3 = TestStep3(field1: "aaa", field2: "bbb", field3: ":", ffour: 123)
    let step11 = Step(step1)
    let enc11 = try URLEncodedFormEncoder().encode(step11)
    let dec11 = try URLEncodedFormDecoder().decode(Step.self, from: enc11)
    XCTAssertEqual(dec11, step11)
    let step22 = Step(step2)
    let enc22 = try URLEncodedFormEncoder().encode(step22)
    let dec22 = try URLEncodedFormDecoder().decode(Step.self, from: enc22)
    XCTAssertEqual(dec22, step22)
    let step33 = Step(step3)
    let enc33 = try URLEncodedFormEncoder().encode(step33)
    let dec33 = try URLEncodedFormDecoder().decode(Step.self, from: enc33)
    XCTAssertEqual(dec33, step33)
  }

}

// MARK: - TestStep1

private struct TestStep1: StepPayload, Hashable {

  static let name: String = "aaa1"

  let field1: String
  let field2: String
  let field3: String

}

// MARK: - TestStep2

private struct TestStep2: StepPayload, Hashable {

  static let name: String = "aaa2"

  let field1: String
  let field2: String
  let field3: String

}

// MARK: - TestStep3

private struct TestStep3: StepPayload, Hashable {

  static let name: String = "aaa3"

  let field1: String
  let field2: String
  let field3: String
  let ffour: Int

}
