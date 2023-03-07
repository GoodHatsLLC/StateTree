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
      .start(root: DeepNode(depth: 1))

    XCTAssert(testTree._info?.isActive == true)

    lifetime.dispose()

    XCTAssertFalse(testTree._info?.isActive == true)
  }

  @TreeActor
  func test_count() async throws {
    let testTree = Tree.main

    XCTAssertEqual(0, testTree._info?.nodeCount ?? 0)

    let lifetime = try testTree
      .start(root: DeepNode(depth: 3))

    XCTAssertEqual(4, testTree._info?.depth)
    XCTAssertEqual(11, testTree._info?.nodeCount)

    lifetime.rootNode.depth = 3
    XCTAssertEqual(4, testTree._info?.depth)
    XCTAssertEqual(11, testTree._info?.nodeCount)

    lifetime.rootNode.depth = 5

    XCTAssertEqual(6, testTree._info?.depth)
    XCTAssertEqual(17, testTree._info?.nodeCount)

    lifetime.rootNode.depth = 3
    XCTAssertEqual(4, testTree._info?.depth)
    XCTAssertEqual(11, testTree._info?.nodeCount)

    lifetime.rootNode.depth = 1
    XCTAssertEqual(2, testTree._info?.depth)
    XCTAssertEqual(3, testTree._info?.nodeCount)

    lifetime.dispose()
    XCTAssertEqual(0, testTree._info?.depth ?? 0)
    XCTAssertEqual(0, testTree._info?.nodeCount ?? 0)
  }

}

// MARK: InfoTests.DeepNode

extension InfoTests {

  struct DeepNode: Node {

    @Route(ANode.self) var one
    @Route(BNode.self) var next
    @Value var depth: Int

    var rules: some Rules {
      $one.route(to: ANode())
      if depth > 0 {
        $next.route {
          BNode(parentDepth: $depth)
        }
      }
    }
  }

  struct ANode: Node {
    var rules: some Rules { () }
  }

  struct BNode: Node {

    @Route(BNode.self) var next
    @Route(BNode.self) var always
    @Value var depth: Int = 0
    @Value var alwaysZero = 0
    @Projection var parentDepth: Int

    var rules: some Rules {
      OnChange(parentDepth) { _ in
        depth = parentDepth - 1
      }
      if depth > 0 {
        $next.route {
          BNode(parentDepth: $depth)
        }
      }
      if depth > -1 {
        $always.route(to: BNode(parentDepth: $alwaysZero))
      }
    }
  }

}
