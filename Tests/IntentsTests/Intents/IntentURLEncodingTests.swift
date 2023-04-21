import XCTest
@testable import Intents

// MARK: - IntentURLEncodingTests

final class IntentURLEncodingTests: XCTestCase {

  func test_encoding() throws {
    let step1 = TestStep1(field1: "one", field2: "two", field3: "three")
    let step2 = TestStep2(field1: "|", field2: "/", field3: "abc")
    let step3 = TestStep3(field1: "aaa", field2: "bbb", field3: "ccc", ffour: 123)
    let intent = try Intent(
      step1,
      step2,
      step3
    )

    let encodedString = try intent.urlEncode()
    let stepStrings = encodedString.split(separator: "/")
    XCTAssertEqual(stepStrings.count, 3)

    let step1Strings = stepStrings[0].split(separator: "&")
    XCTAssertEqual(step1Strings.count, 4)
    XCTAssertEqual(
      Set(step1Strings),
      Set([
        "name=aaa1",
        "payload[field3]=three",
        "payload[field2]=two",
        "payload[field1]=one",
      ])
    )

    let step2Strings = stepStrings[1].split(separator: "&")
    XCTAssertEqual(step2Strings.count, 4)
    XCTAssertEqual(
      Set(step2Strings),
      Set([
        "payload[field3]=abc",
        "payload[field2]=%2F",
        "payload[field1]=%7C",
        "name=aaa2",
      ])
    )

    let step3Strings = stepStrings[2].split(separator: "&")
    XCTAssertEqual(step3Strings.count, 5)
    XCTAssertEqual(
      Set(step3Strings),
      Set([
        "name=aaa3",
        "payload[ffour]=123",
        "payload[field3]=ccc",
        "payload[field2]=bbb",
        "payload[field1]=aaa",
      ])
    )
  }

  func test_decoding() throws {
    let step1 = TestStep1(field1: "one", field2: "two", field3: "three")
    let step2 = TestStep2(field1: "|", field2: "/", field3: "abc")
    let step3 = TestStep3(field1: "aaa", field2: "bbb", field3: "ccc", ffour: 123)
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
    let step3 = TestStep3(field1: "aaa", field2: "bbb", field3: "ccc", ffour: 123)
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
