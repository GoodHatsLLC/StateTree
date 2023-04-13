import Disposable
@_spi(Implementation) import StateTree
import XCTest

// MARK: - OnChangeTests

final class OnChangeTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_playground() async throws {
    let tree = Tree(root: OnChangeNode())
    try tree.start()
    let node = try tree.assume.rootNode

    XCTAssertEqual(node.intVal, 0)
    XCTAssertEqual(node.derived, 0)

    node.intVal = 5

    XCTAssertEqual(node.intVal, 5)
    XCTAssertEqual(node.derived, -5)

    node.intVal = 3

    XCTAssertEqual(node.intVal, 3)
    XCTAssertEqual(node.derived, -3)
  }
}

// MARK: - OnChangeNode

struct OnChangeNode: Node {
  @Value var intVal = 0
  @Value var derived = 0
  var rules: some Rules {
    OnChange(intVal) { value in
      derived = -value
    }
  }
}
