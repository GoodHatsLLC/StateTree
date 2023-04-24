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
    try tree.start()
      .autostop()
      .stage(on: stage)

    XCTAssert(try tree.assume.info.isActive == true)

    stage.dispose()

    XCTAssertThrowsError(try tree.assume.info.isActive == true)
  }

  @TreeActor
  func test_flushUpdateStats() async throws {
    let tree = Tree(root: DeepNode(height: 1))
    try tree.start()
      .autostop()
      .stage(on: stage)

    let stats = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(stats.counts.uniqueTouchedNodes, 1)
    XCTAssertEqual(stats.counts.nodeStarts, 1)
    XCTAssertEqual(stats.counts.nodeUpdates, 1)
    XCTAssertEqual(stats.counts.allNodeEvents, 2)
    XCTAssertGreaterThan(stats.durations.nodeUpdates, 0)

    let reflush = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(reflush.counts.uniqueTouchedNodes, 0)
    XCTAssertEqual(reflush.counts.allNodeEvents, 0)
    XCTAssertEqual(reflush.durations.nodeUpdates, 0)

    try tree.assume.rootNode.height = 3

    let postUpdate = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(postUpdate.counts.uniqueTouchedNodes, 3)
    XCTAssertEqual(postUpdate.counts.allNodeEvents, 5)
    XCTAssertGreaterThan(postUpdate.durations.nodeUpdates, 0)

    try tree.assume.rootNode.height = 22

    let postUpdate2 = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(postUpdate2.counts.uniqueTouchedNodes, 32)
    XCTAssertEqual(postUpdate2.counts.allNodeEvents, 61)
    XCTAssertGreaterThan(postUpdate2.durations.nodeUpdates, 0)

    try tree.assume.rootNode.height = 22

    let postUpdateDupe = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(postUpdateDupe.counts.uniqueTouchedNodes, 0)
    XCTAssertEqual(postUpdateDupe.counts.allNodeEvents, 0)
    let postUpdateDupeTime = postUpdateDupe.durations.nodeUpdates
    XCTAssertGreaterThan(postUpdateDupeTime, 0)

    try tree.assume.rootNode.height = 1

    let postUpdateStops = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(postUpdateStops.counts.allNodeEvents, 32)
    XCTAssertEqual(postUpdateStops.counts.nodeStarts, 0)
    XCTAssertEqual(postUpdateStops.counts.nodeUpdates, 1)
    XCTAssertEqual(postUpdateStops.counts.nodeStops, 31)
    XCTAssertGreaterThan(postUpdateStops.durations.nodeUpdates, 0)
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
