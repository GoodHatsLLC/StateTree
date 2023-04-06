import Behavior
import XCTest

final class BehaviorIDTests: XCTestCase {

  func test_stable_hashing() throws {
    let one: BehaviorID = .auto()
    let two: BehaviorID = .auto()
    let three: BehaviorID = .auto()
    let four: BehaviorID = .auto()
    let five: BehaviorID = .auto()
    let six: BehaviorID = .id("custom-name")
    XCTAssertEqual(one, .id("282e55075e4bd4f6-auto"))
    XCTAssertEqual(two, .id("86ad08848d6f91ee-auto"))
    XCTAssertEqual(three, .id("cda8a581217057df-auto"))
    XCTAssertEqual(four, .id("09de1f3d379dfe2d-auto"))
    XCTAssertEqual(five, .id("d13e4f593f822bce-auto"))
    XCTAssertEqual(six, .id("custom-name"))
  }

}
