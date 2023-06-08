import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - UpdateStatsTests

final class UpdateStatsTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
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

}

// MARK: UpdateStatsTests.DeepNode

extension UpdateStatsTests {

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
        Serve(BNode(parentHeight: $sideChainHeight), at: $sideChain)
      }
    }
  }

}
