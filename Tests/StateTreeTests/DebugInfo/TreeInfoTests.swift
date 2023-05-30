import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - TreeInfoTests

final class TreeInfoTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_isActive() async throws {
    let tree = Tree(root: DeepNode(height: 1))
    try tree.start()
      .autostop()
      .stage(on: stage)

    XCTAssert(try tree.assume.info.isActive == true)

    stage.dispose()

    XCTAssertThrowsError(try tree.assume.info.isActive == true)
  }

  @TreeActor
  func test_count() async throws {
    let testTree = Tree(root: DeepNode(height: 7))

    try testTree.start()
      .autostop()
      .stage(on: stage)

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
    XCTAssertThrowsError(try testTree.assume.info.height)
    XCTAssertThrowsError(try testTree.assume.info.nodeCount)
  }

}

// MARK: TreeInfoTests.DeepNode

extension TreeInfoTests {

  struct DeepNode: Node {

    @Route var next: BNode? = nil
    @Value var height: Int

    var rules: some Rules {
      if height > 1 {
        Serve(BNode(parentHeight: $height), at: $next)
      }
    }
  }

  struct BNode: Node {

    @Route var next: BNode? = nil
    @Route var sideChain: BNode? = nil
    @Value var sideChainHeight: Int = 11
    @Value var height: Int = 0
    @Projection var parentHeight: Int

    var rules: some Rules {
      OnUpdate(parentHeight) { _ in
        height = parentHeight - 1
      }
      if height > 1 {
        Serve(BNode(parentHeight: $height), at: $next)
      }
      if height == 11 {
        Serve(.init(parentHeight: $sideChainHeight), at: $sideChain)
      }
    }
  }

}
