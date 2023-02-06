import TreeState
import XCTest

final class AnyTreeStateTests: XCTestCase {

  func testEquatable() throws {
    XCTAssertEqual(AnyTreeState("1"), AnyTreeState("1"))
    XCTAssertEqual(AnyTreeState(5), AnyTreeState(5))
    XCTAssertEqual(AnyTreeState(true), AnyTreeState(true))
    XCTAssertNotEqual(AnyTreeState("1"), AnyTreeState(1))
    XCTAssertNotEqual(AnyTreeState(3), AnyTreeState(1))
    XCTAssertNotEqual(AnyTreeState(false), AnyTreeState(true))
  }

}
