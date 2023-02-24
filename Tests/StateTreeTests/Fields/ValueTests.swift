import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - ValueTests

@TreeActor
final class ValueTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  func test_value() throws {
    let tree = try Tree.main
      .start(root: ValueTestHost())
    tree.stage(on: stage)
    let node = tree.rootNode

    XCTAssertNil(node.val)
    node.val = 1
    XCTAssertEqual(node.val, 1)
    node.val = 2
    XCTAssertEqual(node.val, 2)
  }
}

extension ValueTests {

  struct ValueTestHost: Node {

    @Route(SubnodeA.self, SubnodeB.self, SubnodeC.self) var route
    @Route(SubnodeA.self) var otherRoute
    @Value var val: Int?

    var rules: some Rules {
      switch val {
      case 1:
        $route.route { .a(SubnodeA()) }
      case 2:
        $route.route { .b(SubnodeB()) }
      case 3:
        $route.route { .c(SubnodeC(value: $val)) }
      default:
        $otherRoute.route { SubnodeA() }
      }
    }
  }

  // MARK: - SubnodeA

  struct SubnodeA: Node {

    @Value var rating = 101
    @Value var arrayState = [true, false, true]
    @Value var stringState = "101"

    var rules: some Rules { .none }

  }

  // MARK: - SubnodeB

  struct SubnodeB: Node {
    @Value var floatState = 101.0
    var rules: some Rules { .none }
  }

  // MARK: - SubnodeC

  struct SubnodeC: Node {
    struct State: TreeState {
      var value = "👀"
    }

    @Projection var value: Int?
    @Value var structState = State()
    var rules: some Rules { .none }
  }
}
