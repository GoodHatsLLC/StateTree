import Disposable
import Emitter
import TreeActor
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - RoutingTests

final class RoutingTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_defaultSingleRoute() async throws {
    let tree = Tree(root: TestSingleDefault())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssertEqual(root.node.next.derived, "Default++")
  }

  @TreeActor
  func test_nonDefaultSingleRoute() async throws {
    let tree = Tree(root: TestSingleOverride())
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
    let tree = Tree(root: TestSingleDynamicOverride())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update1 = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(root.node.next.derived, "Default++")

    root.node.shouldOverride = true
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update2 = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(root.node.next.derived, "Override++")

    root.node.shouldOverride = false
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update3 = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(root.node.next.derived, "Default++")

    root.node.otherValue = "Non-Router-Triggering"
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update4 = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(root.node.next.derived, "Default++")
  }

}

// MARK: RoutingTests.TestSingleDefault

extension RoutingTests {

  struct TestSingleDefault: Node {
    @Route var next = ChildRouteNode(name: "Default")
    var rules: some Rules {
      .none
    }
  }

  struct TestSingleOverride: Node {
    @Route var next = ChildRouteNode(name: "Default")
    var rules: some Rules {
      $next.route {
        ChildRouteNode(name: "Override")
      }
    }
  }

  struct TestSingleDynamicOverride: Node {
    @Route var next = ChildRouteNode(name: "Default")
    @Value var shouldOverride = false
    @Value var otherValue = "Other"
    var rules: some Rules {
      if shouldOverride {
        $next.route {
          ChildRouteNode(name: "Override")
        }
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
