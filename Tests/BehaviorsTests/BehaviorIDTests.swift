import Behaviors
import XCTest

final class BehaviorIDTests: XCTestCase {

  func test_stable_hashing() throws {
    let one: BehaviorID = .auto()
    let two: BehaviorID = .auto()
    let three: BehaviorID = .auto()
    let four: BehaviorID = .auto()
    let five: BehaviorID = .auto()
    let six: BehaviorID = .id("custom-name")
    XCTAssertEqual(one, .id("ea29158a961227e7"))
    XCTAssertEqual(two, .id("05753d542c131b3f"))
    XCTAssertEqual(three, .id("83c4469198801925"))
    XCTAssertEqual(four, .id("f49bac42475760f9"))
    XCTAssertEqual(five, .id("9abbb59b6a4c28e9"))
    XCTAssertEqual(six, .id("custom-name"))
  }

}
