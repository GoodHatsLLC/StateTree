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
    let testTree = Tree.main

    XCTAssertFalse(testTree._info?.isActive == true)

    let lifetime = try testTree
      .start(root: DeepNode(height: 1))

    XCTAssert(testTree._info?.isActive == true)

    lifetime.dispose()

    XCTAssertFalse(testTree._info?.isActive == true)
  }

  @TreeActor
  func test_count() async throws {
    let testTree = Tree.main

    XCTAssertEqual(0, testTree._info?.nodeCount ?? 0)

    let lifetime = try testTree
      .start(root: DeepNode(height: 7))

    XCTAssertEqual(7, testTree._info?.height)
    XCTAssertEqual(7, testTree._info?.nodeCount)

    lifetime.rootNode.height = 3
    XCTAssertEqual(3, testTree._info?.height)
    XCTAssertEqual(3, testTree._info?.nodeCount)

    lifetime.rootNode.height = 2
    XCTAssertEqual(2, testTree._info?.height)
    XCTAssertEqual(2, testTree._info?.nodeCount)

    lifetime.rootNode.height = 10

    XCTAssertEqual(10, testTree._info?.height)
    XCTAssertEqual(10, testTree._info?.nodeCount)

    lifetime.rootNode.height = 4
    XCTAssertEqual(4, testTree._info?.height)
    XCTAssertEqual(4, testTree._info?.nodeCount)

    lifetime.rootNode.height = 1
    XCTAssertEqual(1, testTree._info?.height)
    XCTAssertEqual(1, testTree._info?.nodeCount)

    lifetime.rootNode.height = 21

    XCTAssertEqual(21, testTree._info?.height)
    // height above 10 triggers the 10-long side chain
    XCTAssertEqual(31, testTree._info?.nodeCount)

    lifetime.rootNode.height = 10

    XCTAssertEqual(10, testTree._info?.height)
    XCTAssertEqual(10, testTree._info?.nodeCount)

    lifetime.rootNode.height = 25

    XCTAssertEqual(25, testTree._info?.height)
    // height above 10 triggers the 10-long side chain
    XCTAssertEqual(35, testTree._info?.nodeCount)

    lifetime.rootNode.height = 22

    XCTAssertEqual(22, testTree._info?.height)
    XCTAssertEqual(32, testTree._info?.nodeCount)

    lifetime.rootNode.height = 7

    XCTAssertEqual(7, testTree._info?.height)
    XCTAssertEqual(7, testTree._info?.nodeCount)

    lifetime.rootNode.height = 2
    XCTAssertEqual(2, testTree._info?.height)
    XCTAssertEqual(2, testTree._info?.nodeCount)

    lifetime.dispose()
    XCTAssertEqual(0, testTree._info?.height ?? 0)
    XCTAssertEqual(0, testTree._info?.nodeCount ?? 0)
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
