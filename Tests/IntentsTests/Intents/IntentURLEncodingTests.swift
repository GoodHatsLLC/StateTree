import XCTest
@testable import Intents

// MARK: - IntentURLEncodingTests

final class IntentURLEncodingTests: XCTestCase {

  func test_encoding() throws {
    let step1 = TestStep1(field1: "one", field2: "two", field3: "three")
    let step2 = TestStep2(field1: "|", field2: "/", field3: "abc")
    let step3 = TestStep3(field1: "aaa", field2: "bbb", field3: ":", ffour: 123)
    let intent = try Intent(
      step1,
      step2,
      step3
    )

    // steps/aaa1/field1=one&field2=two&field3=three/aaa2/field1=%7C&field2=%2F&field3=abc/aaa3/field2=bbb&field1=aaa&field3=:&ffour=123
    let payload = try intent.urlEncode()
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
    let intent = try Intent(
      step1,
      step2,
      step3
    )

    let encodedString = try intent.urlEncode()
    let decoded = try Intent(urlEncoded: encodedString)
    XCTAssertEqual(intent, decoded)
  }

  func testPrerequisite_anyCodable_encodingDecoding() throws {
    let step = TestStep1(field1: "one", field2: "two", field3: "three")
    let anyCodable = AnyCodable(step)
    let enc = try URLEncodedFormEncoder().encode(anyCodable)
    let dec = try URLEncodedFormDecoder().decode(TestStep1.self, from: enc)
    XCTAssertEqual(dec, step)
  }

  func testPrerequisite_step_encodingDecoding() throws {
    let step1 = TestStep1(field1: "one", field2: "two", field3: "three")
    let step2 = TestStep2(field1: "|", field2: "/", field3: "abc")
    let step3 = TestStep3(field1: "aaa", field2: "bbb", field3: ":", ffour: 123)
    let step11 = try Step(step1)
    let enc11 = try URLEncodedFormEncoder().encode(step11)
    let dec11 = try URLEncodedFormDecoder().decode(Step.self, from: enc11)
    XCTAssertEqual(dec11, step11)
    let step22 = try Step(step2)
    let enc22 = try URLEncodedFormEncoder().encode(step22)
    let dec22 = try URLEncodedFormDecoder().decode(Step.self, from: enc22)
    XCTAssertEqual(dec22, step22)
    let step33 = try Step(step3)
    let enc33 = try URLEncodedFormEncoder().encode(step33)
    let dec33 = try URLEncodedFormDecoder().decode(Step.self, from: enc33)
    XCTAssertEqual(dec33, step33)
  }

}

// MARK: - TestStep1

private struct TestStep1: IntentStepPayload, Equatable {

  static let name: String = "aaa1"

  let field1: String
  let field2: String
  let field3: String

}

// MARK: - TestStep2

private struct TestStep2: IntentStepPayload {

  static let name: String = "aaa2"

  let field1: String
  let field2: String
  let field3: String

}

// MARK: - TestStep3

private struct TestStep3: IntentStepPayload {

  static let name: String = "aaa3"

  let field1: String
  let field2: String
  let field3: String
  let ffour: Int

}
