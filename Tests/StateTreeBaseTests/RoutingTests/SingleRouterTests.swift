import Disposable
import StateTreeBase
import XCTest

// MARK: - SingleRouterTests

final class SingleRouterTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_defaultSingleRoute() async throws {
    let tree = Tree(root: TestDefault())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssertEqual(root.node.next.derived, "Default++")
  }

  @TreeActor
  func test_nonDefaultSingleRoute() async throws {
    let tree = Tree(root: TestOverride())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    XCTAssertEqual(root.node.next.derived, "Override++")
  }

  @TreeActor
  func test_DynamicSingleRoute() async throws {
    let tree = Tree(root: TestDynamicOverride())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update1 = try tree.assume.info.flushUpdateStats().counts
    XCTAssertEqual(root.node.next.derived, "Default++")
    XCTAssertEqual(update1.nodeStarts, 2)
    XCTAssertEqual(update1.nodeUpdates, 2)
    XCTAssertEqual(update1.nodeStops, 0)

    root.node.shouldOverride = true
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update2 = try tree.assume.info.flushUpdateStats().counts
    XCTAssertEqual(root.node.next.derived, "Override++")
    XCTAssertEqual(update2.nodeStarts, 1)
    XCTAssertEqual(update2.nodeUpdates, 2)
    XCTAssertEqual(update2.nodeStops, 1)

    root.node.shouldOverride = false
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update3 = try tree.assume.info.flushUpdateStats().counts
    XCTAssertEqual(root.node.next.derived, "Default++")
    XCTAssertEqual(update3.nodeStarts, 1)
    XCTAssertEqual(update3.nodeUpdates, 2)
    XCTAssertEqual(update3.nodeStops, 1)

    root.node.otherValue = "Non-Router-Triggering"
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update4 = try tree.assume.info.flushUpdateStats().counts
    XCTAssertEqual(root.node.next.derived, "Default++")
    XCTAssertEqual(update4.nodeStarts, 0)
    XCTAssertEqual(update4.nodeUpdates, 1)
    XCTAssertEqual(update4.nodeStops, 0)
  }

}

// MARK: SingleRouterTests.TestDefault

extension SingleRouterTests {

  struct TestDefault: Node {
    @Route var next = ChildRouteNode(name: "Default")
    var rules: some Rules {
      .none
    }
  }

  struct TestOverride: Node {
    @Route var next = ChildRouteNode(name: "Default")
    var rules: some Rules {
      Serve(ChildRouteNode(name: "Override"), at: $next)
    }
  }

  struct TestDynamicOverride: Node {
    @Route var next = ChildRouteNode(name: "Default")
    @Value var shouldOverride = false
    @Value var otherValue = "Other"

    var rules: some Rules {
      if shouldOverride {
        Serve(ChildRouteNode(name: "Override"), at: $next)
      }
    }
  }

  struct ChildRouteNode: Node {
    @Value var name: String
    @Value var derived: String?
    var rules: some Rules {
      OnStart {
        derived = "\(name)++"
      }
    }
  }

}
