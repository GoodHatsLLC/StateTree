import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - InfoTests

final class InfoTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_isActive() async throws {
    let tree = Tree(root: DeepNode(height: 1))
    XCTAssertFalse(try tree.assume.info.isActive == true)
    try tree.start()

    XCTAssert(try tree.assume.info.isActive == true)

    stage.dispose()

    XCTAssertFalse(try tree.assume.info.isActive == true)
  }

  @TreeActor
  func test_count() async throws {
    let testTree = Tree(root: DeepNode(height: 7))

    try testTree.start()

    XCTAssertEqual(7, try testTree.assume.info.height)
    XCTAssertEqual(7, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 3
    XCTAssertEqual(3, try testTree.assume.info.height)
    XCTAssertEqual(3, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 2
    XCTAssertEqual(2, try testTree.assume.info.height)
    XCTAssertEqual(2, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 10

    XCTAssertEqual(10, try testTree.assume.info.height)
    XCTAssertEqual(10, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 4
    XCTAssertEqual(4, try testTree.assume.info.height)
    XCTAssertEqual(4, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 1
    XCTAssertEqual(1, try testTree.assume.info.height)
    XCTAssertEqual(1, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 21

    XCTAssertEqual(21, try testTree.assume.info.height)
    // height above 10 triggers the 10-long side chain
    XCTAssertEqual(31, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 10

    XCTAssertEqual(10, try testTree.assume.info.height)
    XCTAssertEqual(10, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 25

    XCTAssertEqual(25, try testTree.assume.info.height)
    // height above 10 triggers the 10-long side chain
    XCTAssertEqual(35, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 22

    XCTAssertEqual(22, try testTree.assume.info.height)
    XCTAssertEqual(32, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 7

    XCTAssertEqual(7, try testTree.assume.info.height)
    XCTAssertEqual(7, try testTree.assume.info.nodeCount)

    try testTree.assume.rootNode.height = 2
    XCTAssertEqual(2, try testTree.assume.info.height)
    XCTAssertEqual(2, try testTree.assume.info.nodeCount)

    stage.dispose()
    XCTAssertEqual(0, try testTree.assume.info.height)
    XCTAssertEqual(0, try testTree.assume.info.nodeCount)
  }

}

// MARK: InfoTests.DeepNode

extension InfoTests {

  struct DeepNode: Node {

    @Route(BNode.self) var next
    @Value var height: Int

    var rules: some Rules {
      if height > 1 {
        $next.route {
          BNode(parentHeight: $height)
        }
      }
    }
  }

  struct BNode: Node {

    @Route(BNode.self) var next
    @Route(BNode.self) var sideChain
    @Value var sideChainHeight: Int = 11
    @Value var height: Int = 0
    @Projection var parentHeight: Int

    var rules: some Rules {
      OnChange(parentHeight) { _ in
        height = parentHeight - 1
      }
      if height > 1 {
        $next.route {
          BNode(parentHeight: $height)
        }
      }
      if height == 11 {
        $sideChain.route(to: .init(parentHeight: $sideChainHeight))
      }
    }
  }

}
