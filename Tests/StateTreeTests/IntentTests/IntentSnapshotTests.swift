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
    let life = try Tree()
      .start(root: PendingNode<ValueSetNode>())

    // The node's values start as false, preventing routing
    XCTAssertEqual(life.rootNode.shouldRoute, false)
    XCTAssertEqual(life.rootNode.mayRoute, false)
    XCTAssertNil(life.rootNode.child)
    // there is no active intent
    XCTAssertNil(life._info.pendingIntent)

    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        PendingNodeStep(shouldRoute: true),
        ValueSetStep(value: 123)
      )
    )
    // signal the intent
    life.signal(intent: intent)

    // intent has not been fully applied and is still pending
    XCTAssertEqual(life.rootNode.shouldRoute, false)
    XCTAssertNil(life.rootNode.child)
    XCTAssertNotNil(life._info.pendingIntent)

    // save the current state
    let snapshot = life.snapshot()
    // we can poke into the implementation to verify intent exists
    XCTAssertNotNil(snapshot.activeIntent)

    // tear down the tree
    life.dispose()
    XCTAssertFalse(life._info.isActive)
    XCTAssert(life._info.isConsistent)
    XCTAssertNil(life._info.pendingIntent)

    // create a new tree from the saved state
    let life2 = try Tree()
      .start(root: PendingNode<ValueSetNode>(), from: snapshot)
    XCTAssert(life2._info.isConsistent)

    // unblock the pending intent
    life2.rootNode.mayRoute = true

    // once the state changes, the intent applies
    XCTAssertEqual(life2.rootNode.shouldRoute, true)
    XCTAssertNotNil(life2.rootNode.child)
    // the snapshot's serialized intent steps apply
    XCTAssertEqual(life2.rootNode.child?.value, 123)

    // and the intent finishes
    XCTAssertNil(life2._info.pendingIntent)
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
