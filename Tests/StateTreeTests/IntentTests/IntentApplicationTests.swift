import Disposable
import Intents
import StateTree
import XCTest

// MARK: - IntentApplicationTests

final class IntentApplicationTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_singleStep_intentApplication() async throws {
    let tree = Tree(root: ValueSetNode())
    try tree.start()

    // No value since intent has not triggered.
    XCTAssertNil(try tree.assume.rootNode.value)
    XCTAssertNil(try tree.assume.info.pendingIntent)
    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        ValueSetStep(value: 123)
      )
    )
    // signal the intent
    try tree.assume.signal(intent: intent)
    // intent has been applied
    XCTAssertEqual(try tree.assume.rootNode.value, 123)
    // and the intent is finished
    XCTAssertNil(try tree.assume.info.pendingIntent)
  }

  @TreeActor
  func test_decodedPayloadStep_intentApplication() async throws {
    let tree = Tree(root: PrivateIntentNode())
    try tree.start()

    // No value is present since the intent has not triggered.
    XCTAssertNil(try tree.assume.rootNode.payload)
    XCTAssertNil(try tree.assume.info.pendingIntent)
    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        PrivateStep(payload: "PAYLOAD")
      )
    )
    // signal the intent
    try tree.assume.signal(intent: intent)
    // intent has been applied
    XCTAssertEqual(try tree.assume.rootNode.payload, "PAYLOAD")
    // and the intent is finished
    XCTAssertNil(try tree.assume.info.pendingIntent)
  }

  @TreeActor
  func test_multiStep_intentApplication() async throws {
    let tree = Tree(root: RoutingIntentNode<ValueSetNode>())
    try tree.start()

    // No routed node since intent has not triggered.
    XCTAssertNil(try tree.assume.rootNode.child)
    XCTAssertNil(try tree.assume.info.pendingIntent)
    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        RouteTriggerStep(shouldRoute: true),
        ValueSetStep(value: 321)
      )
    )
    // signal the intent
    try tree.assume.signal(intent: intent)
    // intent has been applied
    XCTAssertNotNil(try tree.assume.rootNode.child)
    XCTAssertEqual(try tree.assume.rootNode.child?.value, 321)
    // and the intent is finished
    XCTAssertNil(try tree.assume.info.pendingIntent)
  }

  @TreeActor
  func test_nodeSkippingIntentApplication() async throws {
    let tree = Tree(root: RoutingIntentNode<IntermediateNode<ValueSetNode>>())
    try tree.start()

    // No routed node since intent has not triggered.
    XCTAssertNil(try tree.assume.rootNode.child)
    XCTAssertNil(try tree.assume.info.pendingIntent)
    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        // Handled by RoutingIntentNode
        RouteTriggerStep(shouldRoute: true),

        // IntermediateNode has no intent handlers

        // Handled by ValueSetNode
        ValueSetStep(value: 321)
      )
    )
    // signal the intent
    try tree.assume.signal(intent: intent)
    // intent has been applied
    XCTAssertNotNil(try tree.assume.rootNode.child)
    XCTAssertEqual(try tree.assume.rootNode.child?.child?.value, 321)
    // and the intent is finished
    XCTAssertNil(try tree.assume.info.pendingIntent)
  }

  @TreeActor
  func test_singleNodeRepeatedStep_intentApplication() async throws {
    let tree = Tree(root: RepeatStepNode())
    try tree.start()

    // No value since intent has not triggered.
    XCTAssertNil(try tree.assume.rootNode.value1)
    XCTAssertNil(try tree.assume.rootNode.value2)
    XCTAssertNil(try tree.assume.info.pendingIntent)
    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        RepeatStep1(value: "stepOne"),
        RepeatStep2(value: "stepTwo")
      )
    )
    // signal the intent
    try tree.assume.signal(intent: intent)
    // intent has been applied
    XCTAssertEqual(try tree.assume.rootNode.value1, "stepOne")
    XCTAssertEqual(try tree.assume.rootNode.value2, "stepTwo")
    // and the intent is finished
    XCTAssertNil(try tree.assume.info.pendingIntent)
  }

  @TreeActor
  func test_pendingStep_intentApplication() async throws {
    let tree = Tree(root: PendingNode<ValueSetNode>())
    try tree.start()

    // The node's values start as false, preventing routing
    XCTAssertEqual(try tree.assume.rootNode.shouldRoute, false)
    XCTAssertEqual(try tree.assume.rootNode.mayRoute, false)
    XCTAssertNil(try tree.assume.rootNode.child)
    // there is no active intent
    XCTAssertNil(try tree.assume.info.pendingIntent)

    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        PendingNodeStep(shouldRoute: true)
      )
    )
    // signal the intent
    try tree.assume.signal(intent: intent)

    // intent has not been fully applied and is still active
    XCTAssertEqual(try tree.assume.rootNode.shouldRoute, false)
    XCTAssertNil(try tree.assume.rootNode.child)
    XCTAssertNotNil(try tree.assume.info.pendingIntent)

    try tree.assume.rootNode.mayRoute = true

    // once the state changes, the intent applies and finishes
    XCTAssertEqual(try tree.assume.rootNode.shouldRoute, true)
    XCTAssertNotNil(try tree.assume.rootNode.child)
    XCTAssertNil(try tree.assume.info.pendingIntent)
  }

  @TreeActor
  func test_maybeInvalidatedIntent() async throws {
    try await runTest(shouldInvalidate: false)
    stage.reset()
    try await runTest(shouldInvalidate: true)

    func runTest(shouldInvalidate: Bool) async throws {
      let tree = Tree(root: InvalidatingNode<PendingNode<ValueSetNode>>())
      try tree.start()

      // The node's values start false preventing routing
      XCTAssertEqual(try tree.assume.rootNode.shouldRoute, false)
      XCTAssertEqual(try tree.assume.rootNode.validNext, .initial)
      XCTAssertNil(try tree.assume.rootNode.initialNext)
      XCTAssertNil(try tree.assume.rootNode.laterNext)
      // there is no active intent
      XCTAssertNil(try tree.assume.info.pendingIntent)

      // make the intent
      let intent = try XCTUnwrap(
        Intent(
          MaybeInvalidatedStep(shouldRoute: true),
          PendingNodeStep(shouldRoute: true),
          ValueSetStep(value: 111)
        )
      )
      // signal the intent
      try tree.assume.signal(intent: intent)

      // the first intent applies triggering a route to 'initialNext'
      XCTAssertEqual(try tree.assume.rootNode.shouldRoute, true)
      XCTAssertNotNil(try tree.assume.rootNode.initialNext)
      // (the other route to the same node type remains disabled due to the 'validNext' state)
      XCTAssertEqual(try tree.assume.rootNode.validNext, .initial)
      XCTAssertNil(try tree.assume.rootNode.laterNext)
      // but the unrelated 'mayRoute' state prevents routing
      XCTAssertEqual(try tree.assume.rootNode.initialNext?.mayRoute, false)
      // the second intent step can not yet apply
      XCTAssertEqual(try tree.assume.rootNode.initialNext?.shouldRoute, false)
      // and so neither can the third
      XCTAssertNil(try tree.assume.rootNode.initialNext?.child?.value)
      // the intent remains active as its step is pending
      XCTAssertNotNil(try tree.assume.info.pendingIntent)

      if shouldInvalidate {
        let initialChildType = type(of: try tree.assume.rootNode.initialNext)

        // 'mayRoute' keeps the second step pending, while root node's state changes
        try tree.assume.rootNode.validNext = .later

        // the root's initial child has deallocated and and a new identically typed child is routed
        XCTAssertNil(try tree.assume.rootNode.initialNext)
        XCTAssertNotNil(try tree.assume.rootNode.laterNext)
        let laterChildType = type(of: try tree.assume.rootNode.laterNext)
        XCTAssertEqual("\(initialChildType)", "\(laterChildType)")

        // but the intent has finished
        XCTAssertNil(try tree.assume.info.pendingIntent)
        // and the second and third steps never execute on the new node
        XCTAssertEqual(try tree.assume.rootNode.laterNext?.shouldRoute, false)

        // (even if the state blocking the previous node is changed in the new one)
        try tree.assume.rootNode.initialNext?.mayRoute = true
        XCTAssertEqual(try tree.assume.rootNode.laterNext?.shouldRoute, false)

      } else {
        // a change to the blocking mayRoute releases the second step from pending and allow
        // the third to execute and the intent to finish
        try tree.assume.rootNode.initialNext?.mayRoute = true
        XCTAssertNotNil(try tree.assume.rootNode.initialNext?.child)
        XCTAssertEqual(try tree.assume.rootNode.initialNext?.child?.value, 111)
        XCTAssertNil(try tree.assume.info.pendingIntent)
      }
    }
  }

}

// MARK: - DefaultInitNode

/// Helper allowing this test file to instantiate generic node.
private protocol DefaultInitNode: Node {
  init()
}

/// Intent definitions
extension IntentApplicationTests {

  fileprivate struct RepeatStep1: StepPayload {
    static let name = "repeat-1"
    let value: String
  }

  fileprivate struct RepeatStep2: StepPayload {
    static let name = "repeat-2"
    let value: String
  }

  fileprivate struct ValueSetStep: StepPayload {
    static let name = "value-set-step"
    let value: Int
  }

  fileprivate struct RouteTriggerStep: StepPayload {
    static let name = "route-trigger-step"
    let shouldRoute: Bool
  }

  fileprivate struct PendingNodeStep: StepPayload {
    static let name = "pending-step"
    let shouldRoute: Bool
  }

  fileprivate struct MaybeInvalidatedStep: StepPayload {
    static let name = "maybe-invalid"
    let shouldRoute: Bool
  }

  fileprivate struct PrivateStep: StepPayload {
    static let name = "private-step"
    let payload: String
  }

}

/// Test Node definitions
extension IntentApplicationTests {

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

  fileprivate struct PrivateIntentNode: DefaultInitNode {
    @Value var payload: String?
    var rules: some Rules {
      OnIntent(PrivateStep.self) { step in
        .act {
          payload = step.payload
        }
      }
    }
  }

  fileprivate struct RepeatStepNode: DefaultInitNode {

    @Value var value1: String?
    @Value var value2: String?
    var rules: some Rules {
      OnIntent(RepeatStep1.self) { step in
        .act {
          value1 = step.value
        }
      }
      OnIntent(RepeatStep2.self) { step in
        .act {
          value2 = step.value
        }
      }
    }
  }

  fileprivate struct RoutingIntentNode<Next: DefaultInitNode>: DefaultInitNode {
    @Route var child: Next? = nil
    @Value private var shouldRoute: Bool = false
    var rules: some Rules {
      if shouldRoute {
        Serve(Next(), at: $child)
      }
      OnIntent(RouteTriggerStep.self) { step in
        .act {
          shouldRoute = step.shouldRoute
        }
      }
    }
  }

  fileprivate struct IntermediateNode<Next: DefaultInitNode>: DefaultInitNode {
    @Route var child: Next? = nil
    var rules: some Rules {
      Serve(Next(), at: $child)
    }
  }

  fileprivate struct PendingNode<Next: DefaultInitNode>: DefaultInitNode {

    @Value var mayRoute: Bool = false
    @Value var shouldRoute: Bool = false
    @Route var child: Next? = nil

    var rules: some Rules {
      if shouldRoute {
        Serve(Next(), at: $child)
      }
      OnIntent(PendingNodeStep.self) { step in
        mayRoute
          ? .act { shouldRoute = step.shouldRoute }
          : .pend
      }
    }
  }

  fileprivate struct InvalidatingNode<Next: DefaultInitNode>: DefaultInitNode {
    @Route var initialNext: Next? = nil
    @Route var laterNext: Next? = nil
    @Value var validNext: ValidNext = .initial
    @Value var shouldRoute: Bool = false

    enum ValidNext: Codable {
      case initial
      case later
    }

    var rules: some Rules {
      if shouldRoute {
        switch validNext {
        case .initial: Serve(Next(), at: $initialNext)
        case .later: Serve(Next(), at: $laterNext)
        }
      }
      OnIntent(MaybeInvalidatedStep.self) { step in
        .act {
          shouldRoute = step.shouldRoute
        }
      }
    }

  }

}
