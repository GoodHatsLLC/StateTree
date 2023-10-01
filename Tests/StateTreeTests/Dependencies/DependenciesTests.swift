import Disposable
@_spi(Internal) import StateTree
import XCTest

class DependencyValuesTests: XCTestCase {

  func test_defaults() throws {
    let defaults = DependencyValues.defaults

    // defaults are accessible as defined
    XCTAssertEqual(defaults[KeyOne.self], false)
    XCTAssertEqual(defaults[KeyTwo.self], "default")
    XCTAssertEqual(defaults[KeyThree.self], Int.max)
  }

  func test_inject() throws {
    var defaults = DependencyValues.defaults

    // start with only one changed
    var modified = defaults.inject(\.one, value: true)

    // only one changed
    XCTAssertEqual(modified[KeyOne.self], true)
    XCTAssertEqual(modified[KeyTwo.self], "default")
    XCTAssertEqual(modified[KeyThree.self], Int.max)

    // update the rest
    modified = modified.inject(\.two, value: "YOLO")
    modified = modified.inject(\.three, value: Int.min)

    // all are changed
    XCTAssertEqual(modified[KeyOne.self], true)
    XCTAssertEqual(modified[KeyTwo.self], "YOLO")
    XCTAssertEqual(modified[KeyThree.self], Int.min)
  }

}
