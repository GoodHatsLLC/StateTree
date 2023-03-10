import StateTree
import XCTest

final class BehaviorIDTests: XCTestCase {

  func test_stable_hashing() throws {
    let one: BehaviorID = .auto()
    let two: BehaviorID = .auto()
    let three: BehaviorID = .auto()
    let four: BehaviorID = .auto()
    let five: BehaviorID = .auto()
    let six: BehaviorID = .id("custom-name")
    XCTAssertEqual(one, .id("6ee0504f07e75c21"))
    XCTAssertEqual(two, .id("31deb228ac5aaa21"))
    XCTAssertEqual(three, .id("9cd39e43ee42fefe"))
    XCTAssertEqual(four, .id("b4becaf8f43d75bf"))
    XCTAssertEqual(five, .id("14b99e417fe6ba26"))
    XCTAssertEqual(six, .id("custom-name"))
  }

}
