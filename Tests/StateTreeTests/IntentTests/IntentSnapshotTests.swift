import Disposable
import Intents
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
    try tree.start()
      .autostop()
      .stage(on: stage)
    // The node's values start as false, preventing routing
    XCTAssertEqual(try tree.assume.rootNode.shouldRoute, false)
    XCTAssertEqual(try tree.assume.rootNode.mayRoute, false)
    XCTAssertNil(try tree.assume.rootNode.child)
    // there is no active intent
    XCTAssertNil(try tree.assume.info.pendingIntent)

    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        PendingNodeStep(shouldRoute: true),
        ValueSetStep(value: 123)
      )
    )
    // signal the intent
    try tree.assume.signal(intent: intent)

    // intent has not been fully applied and is still pending
    XCTAssertEqual(try tree.assume.rootNode.shouldRoute, false)
    XCTAssertNil(try tree.assume.rootNode.child)
    XCTAssertNotNil(try tree.assume.info.pendingIntent)

    // save the current state
    let snapshot = try tree.assume.snapshot()
    // we can poke into the implementation to verify intent exists
    XCTAssertNotNil(snapshot.activeIntent)

    // tear down the tree
    stage.reset()
    XCTAssertThrowsError(try tree.assume.info.isActive)

    // create a new tree from the saved state
    let tree2 = Tree(root: PendingNode<ValueSetNode>(), from: snapshot)
    try tree2.start(from: snapshot)
      .autostop()
      .stage(on: stage)

    XCTAssert(try tree2.assume.info.isConsistent)

    // unblock the pending intent
    try tree2.assume.rootNode.mayRoute = true

    // once the state changes, the intent applies
    XCTAssertEqual(try tree2.assume.rootNode.shouldRoute, true)
    XCTAssertNotNil(try tree2.assume.rootNode.child)
    // the snapshot's serialized intent steps apply
    XCTAssertEqual(try tree2.assume.rootNode.child?.value, 123)

    // and the intent finishes
    XCTAssertNil(try tree2.assume.info.pendingIntent)
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
        .act {
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
          ? .act { shouldRoute = step.shouldRoute }
          : .pend
      }
    }
  }

}
