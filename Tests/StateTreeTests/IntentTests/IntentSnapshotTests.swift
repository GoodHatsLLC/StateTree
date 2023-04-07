import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - IntentSnapshotTests

final class IntentSnapshotTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_intentSnapshot_restoration() async throws {
    let tree = Tree(root: PendingNode<ValueSetNode>())
    await tree.run(on: stage)
    // The node's values start as false, preventing routing
    XCTAssertEqual(try tree.rootNode.shouldRoute, false)
    XCTAssertEqual(try tree.rootNode.mayRoute, false)
    XCTAssertNil(try tree.rootNode.child)
    // there is no active intent
    XCTAssertNil(try tree.info.pendingIntent)

    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        PendingNodeStep(shouldRoute: true),
        ValueSetStep(value: 123)
      )
    )
    // signal the intent
    try tree.signal(intent: intent)

    // intent has not been fully applied and is still pending
    XCTAssertEqual(try tree.rootNode.shouldRoute, false)
    XCTAssertNil(try tree.rootNode.child)
    XCTAssertNotNil(try tree.info.pendingIntent)

    // save the current state
    let snapshot = try tree.snapshot()
    // we can poke into the implementation to verify intent exists
    XCTAssertNotNil(snapshot.activeIntent)

    // tear down the tree
    stage.reset()
    XCTAssertFalse(try tree.info.isActive)
    XCTAssert(try tree.info.isConsistent)
    XCTAssertNil(try tree.info.pendingIntent)

    // create a new tree from the saved state
    let tree2 = Tree(root: PendingNode<ValueSetNode>(), from: snapshot)
    await tree2.run(on: stage)
    XCTAssert(try tree2.info.isConsistent)

    // unblock the pending intent
    try tree2.rootNode.mayRoute = true

    // once the state changes, the intent applies
    XCTAssertEqual(try tree2.rootNode.shouldRoute, true)
    XCTAssertNotNil(try tree2.rootNode.child)
    // the snapshot's serialized intent steps apply
    XCTAssertEqual(try tree2.rootNode.child?.value, 123)

    // and the intent finishes
    XCTAssertNil(try tree2.info.pendingIntent)
  }
}

// MARK: - DefaultInitNode

/// Helper allowing this test file to instantiate generic node.
private protocol DefaultInitNode: Node {
  init()
}

/// Intent definitions
extension IntentSnapshotTests {

  fileprivate struct ValueSetStep: IntentStep {
    static let name = "value-set-step"
    let value: Int
  }

  fileprivate struct PendingNodeStep: IntentStep {
    static let name = "pending-step"
    let shouldRoute: Bool
  }

}

/// Test Node definitions
extension IntentSnapshotTests {

  fileprivate struct ValueSetNode: DefaultInitNode {

    @Value var value: Int?

    var rules: some Rules {
      OnIntent(ValueSetStep.self) { step in
        .resolution {
          value = step.value
        }
      }
    }
  }

  fileprivate struct PendingNode<Next: DefaultInitNode>: DefaultInitNode {

    @Value var mayRoute: Bool = false
    @Value var shouldRoute: Bool = false
    @Route(Next.self) var child

    var rules: some Rules {
      if shouldRoute {
        $child.route(to: Next())
      }
      OnIntent(PendingNodeStep.self) { step in
        mayRoute
          ? .resolution { shouldRoute = step.shouldRoute }
          : .pending
      }
    }
  }

}
