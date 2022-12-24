import Dependencies
import XCTest

@MainActor
class DependencyValuesTests: XCTestCase {

  func test_defaults() throws {
    let defaults = DependencyValues.defaults

    // defaults are accessible as defined
    XCTAssertEqual(defaults[KeyOne.self], false)
    XCTAssertEqual(defaults[KeyTwo.self], "default")
    XCTAssertEqual(defaults[KeyThree.self], Int.max)
  }

  func test_inserting() throws {
    let defaults = DependencyValues.defaults

    // start with only one changed
    var modified = defaults.inserting(\.one, value: true)

    // only one changed
    XCTAssertEqual(modified[KeyOne.self], true)
    XCTAssertEqual(modified[KeyTwo.self], "default")
    XCTAssertEqual(modified[KeyThree.self], Int.max)

    // update the rest
    modified = modified.inserting(\.two, value: "YOLO")
    modified = modified.inserting(\.three, value: Int.min)

    // all are changed
    XCTAssertEqual(modified[KeyOne.self], true)
    XCTAssertEqual(modified[KeyTwo.self], "YOLO")
    XCTAssertEqual(modified[KeyThree.self], Int.min)
  }

}
