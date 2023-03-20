import Disposable
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
    let life = try Tree.main
      .start(root: ValueSetNode())
    life.stage(on: stage)

    // No value since intent has not triggered.
    XCTAssertNil(life.rootNode.value)
    XCTAssertNil(life.info.pendingIntent)
    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        ValueSetStep(value: 123)
      )
    )
    // signal the intent
    life.signal(intent: intent)
    // intent has been applied
    XCTAssertEqual(life.rootNode.value, 123)
    // and the intent is finished
    XCTAssertNil(life.info.pendingIntent)
  }

  @TreeActor
  func test_decodedPayloadStep_intentApplication() async throws {
    let life = try Tree.main
      .start(root: PrivateIntentNode())
    life.stage(on: stage)

    // No value is present since the intent has not triggered.
    XCTAssertNil(life.rootNode.payload)
    XCTAssertNil(life.info.pendingIntent)
    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        // `PrivateStep(payload:)` is private. We can't directly instantiate it.
        // PrivateStep(payload: "SOMETHING"),

        // However we can construct a matching step with applicable values
        // using a decodable payload passed to the 'Step' helper.

        // We would usually use a model extracted from a deeplink or equivalent.
        // Here we use the dictionary-init helper.
        Step(name: "private-step", fields: ["payload": "PAYLOAD"])
      )
    )
    // signal the intent
    life.signal(intent: intent)
    // intent has been applied
    XCTAssertEqual(life.rootNode.payload, "PAYLOAD")
    // and the intent is finished
    XCTAssertNil(life.info.pendingIntent)
  }

  @TreeActor
  func test_multiStep_intentApplication() async throws {
    let life = try Tree.main
      .start(root: RoutingIntentNode<ValueSetNode>())
    life.stage(on: stage)

    // No routed node since intent has not triggered.
    XCTAssertNil(life.rootNode.child)
    XCTAssertNil(life.info.pendingIntent)
    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        RouteTriggerStep(shouldRoute: true),
        ValueSetStep(value: 321)
      )
    )
    // signal the intent
    life.signal(intent: intent)
    // intent has been applied
    XCTAssertNotNil(life.rootNode.child)
    XCTAssertEqual(life.rootNode.child?.value, 321)
    // and the intent is finished
    XCTAssertNil(life.info.pendingIntent)
  }

  @TreeActor
  func test_nodeSkippingIntentApplication() async throws {
    let life = try Tree.main
      .start(root: RoutingIntentNode<IntermediateNode<ValueSetNode>>())
    life.stage(on: stage)

    // No routed node since intent has not triggered.
    XCTAssertNil(life.rootNode.child)
    XCTAssertNil(life.info.pendingIntent)
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
    life.signal(intent: intent)
    // intent has been applied
    XCTAssertNotNil(life.rootNode.child)
    XCTAssertEqual(life.rootNode.child?.child?.value, 321)
    // and the intent is finished
    XCTAssertNil(life.info.pendingIntent)
  }

  @TreeActor
  func test_singleNodeRepeatedStep_intentApplication() async throws {
    let life = try Tree.main
      .start(root: RepeatStepNode())
    life.stage(on: stage)

    // No value since intent has not triggered.
    XCTAssertNil(life.rootNode.value1)
    XCTAssertNil(life.rootNode.value2)
    XCTAssertNil(life.info.pendingIntent)
    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        RepeatStep1(value: "stepOne"),
        RepeatStep2(value: "stepTwo")
      )
    )
    // signal the intent
    life.signal(intent: intent)
    // intent has been applied
    XCTAssertEqual(life.rootNode.value1, "stepOne")
    XCTAssertEqual(life.rootNode.value2, "stepTwo")
    // and the intent is finished
    XCTAssertNil(life.info.pendingIntent)
  }

  @TreeActor
  func test_pendingStep_intentApplication() async throws {
    let life = try Tree.main
      .start(root: PendingNode<ValueSetNode>())
    life.stage(on: stage)

    // The node's values start as false, preventing routing
    XCTAssertEqual(life.rootNode.shouldRoute, false)
    XCTAssertEqual(life.rootNode.mayRoute, false)
    XCTAssertNil(life.rootNode.child)
    // there is no active intent
    XCTAssertNil(life.info.pendingIntent)

    // make the intent
    let intent = try XCTUnwrap(
      Intent(
        PendingNodeStep(shouldRoute: true)
      )
    )
    // signal the intent
    life.signal(intent: intent)

    // intent has not been fully applied and is still active
    XCTAssertEqual(life.rootNode.shouldRoute, false)
    XCTAssertNil(life.rootNode.child)
    XCTAssertNotNil(life.info.pendingIntent)

    life.rootNode.mayRoute = true

    // once the state changes, the intent applies and finishes
    XCTAssertEqual(life.rootNode.shouldRoute, true)
    XCTAssertNotNil(life.rootNode.child)
    XCTAssertNil(life.info.pendingIntent)
  }

  @TreeActor
  func test_maybeInvalidatedIntent() async throws {
    try runTest(shouldInvalidate: false)
    stage.reset()
    try runTest(shouldInvalidate: true)

    func runTest(shouldInvalidate: Bool) throws {
      let life = try Tree.main
        .start(root: InvalidatingNode<PendingNode<ValueSetNode>>())
      life.stage(on: stage)

      // The node's values start false preventing routing
      XCTAssertEqual(life.rootNode.shouldRoute, false)
      XCTAssertEqual(life.rootNode.validNext, .initial)
      XCTAssertNil(life.rootNode.initialNext)
      XCTAssertNil(life.rootNode.laterNext)
      // there is no active intent
      XCTAssertNil(life.info.pendingIntent)

      // make the intent
      let intent = try XCTUnwrap(
        Intent(
          MaybeInvalidatedStep(shouldRoute: true),
          PendingNodeStep(shouldRoute: true),
          ValueSetStep(value: 111)
        )
      )
      // signal the intent
      life.signal(intent: intent)

      // the first intent applies triggering a route to 'initialNext'
      XCTAssertEqual(life.rootNode.shouldRoute, true)
      XCTAssertNotNil(life.rootNode.initialNext)
      // (the other route to the same node type remains disabled due to the 'validNext' state)
      XCTAssertEqual(life.rootNode.validNext, .initial)
      XCTAssertNil(life.rootNode.laterNext)
      // but the unrelated 'mayRoute' state prevents routing
      XCTAssertEqual(life.rootNode.initialNext?.mayRoute, false)
      // the second intent step can not yet apply
      XCTAssertEqual(life.rootNode.initialNext?.shouldRoute, false)
      // and so neither can the third
      XCTAssertNil(life.rootNode.initialNext?.child?.value)
      // the intent remains active as its step is pending
      XCTAssertNotNil(life.info.pendingIntent)

      if shouldInvalidate {
        let initialChildType = type(of: life.rootNode.initialNext)

        // 'mayRoute' keeps the second step pending, while root node's state changes
        life.rootNode.validNext = .later

        // the root's initial child has deallocated and and a new identically typed child is routed
        XCTAssertNil(life.rootNode.initialNext)
        XCTAssertNotNil(life.rootNode.laterNext)
        let laterChildType = type(of: life.rootNode.laterNext)
        XCTAssertEqual("\(initialChildType)", "\(laterChildType)")

        // but the intent has finished
        XCTAssertNil(life.info.pendingIntent)
        // and the second and third steps never execute on the new node
        XCTAssertEqual(life.rootNode.laterNext?.shouldRoute, false)

        // (even if the state blocking the previous node is changed in the new one)
        life.rootNode.initialNext?.mayRoute = true
        XCTAssertEqual(life.rootNode.laterNext?.shouldRoute, false)

      } else {
        // a change to the blocking mayRoute releases the second step from pending and allow
        // the third to execute and the intent to finish
        life.rootNode.initialNext?.mayRoute = true
        XCTAssertNotNil(life.rootNode.initialNext?.child)
        XCTAssertEqual(life.rootNode.initialNext?.child?.value, 111)
        XCTAssertNil(life.info.pendingIntent)
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

  fileprivate struct RepeatStep1: IntentStep {
    static let name = "repeat-1"
    let value: String
  }

  fileprivate struct RepeatStep2: IntentStep {
    static let name = "repeat-2"
    let value: String
  }

  fileprivate struct ValueSetStep: IntentStep {
    static let name = "value-set-step"
    let value: Int
  }

  fileprivate struct RouteTriggerStep: IntentStep {
    static let name = "route-trigger-step"
    let shouldRoute: Bool
  }

  fileprivate struct PendingNodeStep: IntentStep {
    static let name = "pending-step"
    let shouldRoute: Bool
  }

  fileprivate struct MaybeInvalidatedStep: IntentStep {
    static let name = "maybe-invalid"
    let shouldRoute: Bool
  }

  fileprivate struct PrivateStep: IntentStep {
    private init(payload _: String) { fatalError() }
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
        .resolution {
          value = step.value
        }
      }
    }
  }

  fileprivate struct PrivateIntentNode: DefaultInitNode {
    @Value var payload: String?
    var rules: some Rules {
      OnIntent(PrivateStep.self) { step in
        .resolution {
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
        .resolution {
          value1 = step.value
        }
      }
      OnIntent(RepeatStep2.self) { step in
        .resolution {
          value2 = step.value
        }
      }
    }
  }

  fileprivate struct RoutingIntentNode<Next: DefaultInitNode>: DefaultInitNode {
    @Route(Next.self) var child
    @Value private var shouldRoute: Bool = false
    var rules: some Rules {
      if shouldRoute {
        $child.route(to: Next())
      }
      OnIntent(RouteTriggerStep.self) { step in
        .resolution {
          shouldRoute = step.shouldRoute
        }
      }
    }
  }

  fileprivate struct IntermediateNode<Next: DefaultInitNode>: DefaultInitNode {
    @Route(Next.self) var child
    var rules: some Rules {
      $child.route(to: Next())
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

  fileprivate struct InvalidatingNode<Next: DefaultInitNode>: DefaultInitNode {
    @Route(Next.self) var initialNext
    @Route(Next.self) var laterNext
    @Value var validNext: ValidNext = .initial
    @Value var shouldRoute: Bool = false

    enum ValidNext: TreeState {
      case initial
      case later
    }

    var rules: some Rules {
      if shouldRoute {
        switch validNext {
        case .initial: $initialNext.route(to: Next())
        case .later: $laterNext.route(to: Next())
        }
      }
      OnIntent(MaybeInvalidatedStep.self) { step in
        .resolution {
          shouldRoute = step.shouldRoute
        }
      }
    }

  }

}
