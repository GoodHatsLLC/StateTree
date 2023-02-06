@_spi(Implementation) import StateTree
import XCTest

// MARK: - OnChangeTests

@TreeActor
final class OnChangeTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  func test_playground() throws {
    let tree = try Tree.main
      .start(root: OnChangeNode())
    tree.stage(on: stage)
    let node = tree.root.node

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