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
    let testTree = Tree_REMOVE.main

    XCTAssertFalse(testTree.info?.isActive == true)

    let lifetime = try testTree
      .start(root: DeepNode(height: 1))

    XCTAssert(testTree.info?.isActive == true)

    lifetime.dispose()

    XCTAssertFalse(testTree.info?.isActive == true)
  }

  @TreeActor
  func test_count() async throws {
    let testTree = Tree_REMOVE.main

    XCTAssertEqual(0, testTree.info?.nodeCount ?? 0)

    let lifetime = try testTree
      .start(root: DeepNode(height: 7))

    XCTAssertEqual(7, testTree.info?.height)
    XCTAssertEqual(7, testTree.info?.nodeCount)

    lifetime.rootNode.height = 3
    XCTAssertEqual(3, testTree.info?.height)
    XCTAssertEqual(3, testTree.info?.nodeCount)

    lifetime.rootNode.height = 2
    XCTAssertEqual(2, testTree.info?.height)
    XCTAssertEqual(2, testTree.info?.nodeCount)

    lifetime.rootNode.height = 10

    XCTAssertEqual(10, testTree.info?.height)
    XCTAssertEqual(10, testTree.info?.nodeCount)

    lifetime.rootNode.height = 4
    XCTAssertEqual(4, testTree.info?.height)
    XCTAssertEqual(4, testTree.info?.nodeCount)

    lifetime.rootNode.height = 1
    XCTAssertEqual(1, testTree.info?.height)
    XCTAssertEqual(1, testTree.info?.nodeCount)

    lifetime.rootNode.height = 21

    XCTAssertEqual(21, testTree.info?.height)
    // height above 10 triggers the 10-long side chain
    XCTAssertEqual(31, testTree.info?.nodeCount)

    lifetime.rootNode.height = 10

    XCTAssertEqual(10, testTree.info?.height)
    XCTAssertEqual(10, testTree.info?.nodeCount)

    lifetime.rootNode.height = 25

    XCTAssertEqual(25, testTree.info?.height)
    // height above 10 triggers the 10-long side chain
    XCTAssertEqual(35, testTree.info?.nodeCount)

    lifetime.rootNode.height = 22

    XCTAssertEqual(22, testTree.info?.height)
    XCTAssertEqual(32, testTree.info?.nodeCount)

    lifetime.rootNode.height = 7

    XCTAssertEqual(7, testTree.info?.height)
    XCTAssertEqual(7, testTree.info?.nodeCount)

    lifetime.rootNode.height = 2
    XCTAssertEqual(2, testTree.info?.height)
    XCTAssertEqual(2, testTree.info?.nodeCount)

    lifetime.dispose()
    XCTAssertEqual(0, testTree.info?.height ?? 0)
    XCTAssertEqual(0, testTree.info?.nodeCount ?? 0)
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
