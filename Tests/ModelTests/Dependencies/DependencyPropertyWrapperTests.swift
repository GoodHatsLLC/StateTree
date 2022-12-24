import Dependencies
import Model
import XCTest

// MARK: - DependencyTests

@MainActor
class DependencyPropertyWrapperTests: XCTestCase {

  @Dependency(\.one) var one: Bool
  @Dependency(\.two) var two: String
  @Dependency(\.three) var three: Int

  func test_defaults() throws {
    XCTAssertEqual(one, false)
    XCTAssertEqual(two, "default")
    XCTAssertEqual(three, Int.max)
  }

  func test_stackPushPop() throws {
    var deps = DependencyValues.defaults
    deps = deps.inserting(\.one, value: true)

    XCTAssertEqual(one, false)
    XCTAssertEqual(two, "default")
    XCTAssertEqual(three, Int.max)

    DependencyStack.push(deps) {
      @Dependency(\.one) var one: Bool
      @Dependency(\.two) var two: String
      @Dependency(\.three) var three: Int

      XCTAssertEqual(one, true)
      XCTAssertEqual(two, "default")
      XCTAssertEqual(three, Int.max)

      deps = deps.inserting(\.two, value: "YOLO")
      deps = deps.inserting(\.three, value: Int.min)

      DependencyStack.push(deps) {
        @Dependency(\.one) var one: Bool
        @Dependency(\.two) var two: String
        @Dependency(\.three) var three: Int

        XCTAssertEqual(one, true)
        XCTAssertEqual(two, "YOLO")
        XCTAssertEqual(three, Int.min)
      }
      XCTAssertEqual(one, true)
      XCTAssertEqual(two, "default")
      XCTAssertEqual(three, Int.max)
    }
    XCTAssertEqual(one, false)
    XCTAssertEqual(two, "default")
    XCTAssertEqual(three, Int.max)
  }
}
