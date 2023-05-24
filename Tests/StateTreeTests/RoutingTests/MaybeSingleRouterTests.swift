import Disposable
import Emitter
import TreeActor
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - MaybeSingleRouterTests

final class MaybeSingleRouterTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_defaultSome_maybeSingleRoute() async throws {
    let tree = Tree(root: TestDefaultSome())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssertEqual(root.node.child?.derived, "Default++")
  }

  @TreeActor
  func test_defaultNone_maybeSingleRoute() async throws {
    let tree = Tree(root: TestDefaultNone())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 1)
    XCTAssertNil(root.node.child)
  }

  @TreeActor
  func test_overrideSome_maybeSingleRoute() async throws {
    let tree = Tree(root: TestOverrideSome())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    XCTAssertEqual(root.node.child?.derived, "Override++")
  }

  @TreeActor
  func test_overrideNone_maybeSingleRoute() async throws {
    let tree = Tree(root: TestOverrideNone())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 1)
    XCTAssert(try tree.assume.info.isConsistent)
    XCTAssertNil(root.node.child)
  }

  @TreeActor
  func test_nonStructural_maybeSingleRoute() async throws {
    // This test shows that a non-structural rule-result change
    // will trigger a node update IFF there is a switch between
    // the .none case and the .some case.
    let tree = Tree(root: TestNonStructuralChange())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 1)
    XCTAssert(try tree.assume.info.isConsistent)

    // default: <= 0, .none case.
    XCTAssertNil(root.node.child)

    // > 0, update to .some case.
    root.node.shouldSome = 1
    XCTAssertNotNil(root.node.child)
    _ = try tree.assume.info.flushUpdateStats()

    // > 0, no change to routed node
    root.node.shouldSome = 2
    let noRestart1 = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(noRestart1.counts.allNodeEvents, 1)
    XCTAssertEqual(noRestart1.counts.nodeUpdates, 1)

    // <= 0, update to .none case
    root.node.shouldSome = -1
    XCTAssertNil(root.node.child)
    _ = try tree.assume.info.flushUpdateStats()

    // <= 0, no change to case
    root.node.shouldSome = -2
    let noRestart2 = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(noRestart2.counts.allNodeEvents, 1)
    XCTAssertEqual(noRestart2.counts.nodeUpdates, 1)
  }

  @TreeActor
  func test_DynamicMaybeSingleRoute() async throws {
    let tree = Tree(root: TestDynamicOverride())
    let root = try tree.start()
    root
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update1 = try tree.assume.info.flushUpdateStats().counts
    XCTAssertEqual(root.node.child?.derived, "Default++")
    XCTAssertEqual(update1.nodeStarts, 2)
    XCTAssertEqual(update1.nodeUpdates, 2)
    XCTAssertEqual(update1.nodeStops, 0)

    root.node.overrideType = .overrideSome
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    XCTAssert(try tree.assume.info.isConsistent)
    let update2 = try tree.assume.info.flushUpdateStats().counts
    XCTAssertEqual(root.node.child?.derived, "Override++")
    XCTAssertEqual(update2.nodeStarts, 1)
    XCTAssertEqual(update2.nodeUpdates, 2)
    XCTAssertEqual(update2.nodeStops, 1)

    root.node.overrideType = .overrideNone
    XCTAssertEqual(try tree.assume.info.nodeCount, 1)
    XCTAssert(try tree.assume.info.isConsistent)
    let update3 = try tree.assume.info.flushUpdateStats().counts
    XCTAssertNil(root.node.child)
    XCTAssertEqual(update3.nodeStarts, 0)
    XCTAssertEqual(update3.nodeUpdates, 1)
    XCTAssertEqual(update3.nodeStops, 1)

    root.node.otherValue = "Non-Router-Triggering"
    XCTAssertEqual(try tree.assume.info.nodeCount, 1)
    XCTAssert(try tree.assume.info.isConsistent)
    let update4 = try tree.assume.info.flushUpdateStats().counts
    XCTAssertNil(root.node.child)
    XCTAssertEqual(update4.nodeStarts, 0)
    XCTAssertEqual(update4.nodeUpdates, 1)
    XCTAssertEqual(update4.nodeStops, 0)
  }

}

// MARK: MaybeSingleRouterTests.TestDefaultSome

extension MaybeSingleRouterTests {

  struct TestDefaultSome: Node {
    @Route var child: ChildRouteNode? = ChildRouteNode(name: "Default")
    var rules: some Rules { () }
  }

  struct TestDefaultNone: Node {
    @Route var child: ChildRouteNode? = nil
    var rules: some Rules { () }
  }

  struct TestOverrideSome: Node {
    @Route var child: ChildRouteNode? = nil
    var rules: some Rules {
      Attach($child, to: ChildRouteNode(name: "Override"))
    }
  }

  struct TestOverrideNone: Node {
    @Route var child: ChildRouteNode? = ChildRouteNode(name: "Default")
    var rules: some Rules {
      Attach($child, to: nil)
    }
  }

  struct TestDynamicOverride: Node {
    enum Override: Codable {
      case overrideSome
      case overrideNone
      case noOverride
    }

    @Route var child: ChildRouteNode? = ChildRouteNode(name: "Default")
    @Value var overrideType: Override = .noOverride
    @Value var otherValue = "Other"

    var rules: some Rules {
      switch overrideType {
      case .noOverride:
        .none
      case .overrideNone:
        Attach(
          $child,
          to: nil
        )
      case .overrideSome:
        Attach(
          $child,
          to: ChildRouteNode(name: "Override")
        )
      }
    }
  }

  struct TestNonStructuralChange: Node {
    @Value var shouldSome = 0
    @Route var child: ChildRouteNode? = nil
    var rules: some Rules {
      Attach(
        $child,
        to: shouldSome > 0 ? ChildRouteNode(name: "Default") : nil
      )
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
