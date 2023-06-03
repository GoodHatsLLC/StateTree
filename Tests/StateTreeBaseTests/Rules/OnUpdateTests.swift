import Disposable
@_spi(Implementation) import StateTreeBase
import TreeActor
import XCTest

// MARK: - OnUpdateTests

final class OnUpdateTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_playground() async throws {
    let tree = Tree(root: OnUpdateNode())
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

// MARK: - OnUpdateNode

struct OnUpdateNode: Node {
  @Value var intVal = 0
  @Value var derived = 0
  var rules: some Rules {
    OnUpdate(intVal) { value in
      derived = -value
    }
  }
}
