import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

final class FieldIDTests: XCTestCase {

  override func setUp() { }
  override func tearDown() { }

  func test_fieldID_decoding() throws {
    let encoded = "v:4:1ED8F444-F4A8-61E0-A5EC-7BE8E4E30373"
    let fieldID = try XCTUnwrap(FieldID(encoded))

    XCTAssertEqual(
      fieldID.description,
      encoded
    )
    XCTAssertEqual(fieldID.offset, 4)
    XCTAssertEqual(fieldID.type, .value)
  }

  func test_bad_fieldID() throws {
    XCTAssertNil(FieldID(""))
    XCTAssertNil(FieldID("v:4:1ED8F444-F4A8-61E0-A5EC-7BE8E4E30373-"))
    XCTAssertNil(FieldID("v:4:1ED8F444-F4A8-61E0-A5EC-7BE8E4E303733"))
    XCTAssertNil(FieldID("v::1ED8F444-F4A8-61E0-A5EC-7BE8E4E30373"))
    XCTAssertNil(FieldID(":4:1ED8F444-F4A8-61E0-A5EC-7BE8E4E30373"))
    XCTAssertNil(FieldID("v:4:1ED8F444-F4A8-61E0-A5EC-7BE8E4E30373]"))
  }

}
