import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - ValueTests

final class ValueTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_value() async throws {
    let tree = Tree(root: ValueTestHost())
    try tree.start()
    let node = try tree.assume.rootNode

    XCTAssertNil(node.val)
    node.val = 1
    XCTAssertEqual(node.val, 1)
    node.val = 2
    XCTAssertEqual(node.val, 2)
  }
}

extension ValueTests {

  struct ValueTestHost: Node {

    @Route var route: Union.Three<SubnodeA, SubnodeB, SubnodeC>? = nil
    @Route var otherRoute: SubnodeA? = nil
    @Value var val: Int?

    var rules: some Rules {
      switch val {
      case 1:
        Attach($route, to: .a(SubnodeA()))
      case 2:
        Attach($route, to: .b(SubnodeB()))
      case 3:
        Attach($route, to: .c(SubnodeC(value: $val)))
      default:
        Attach($otherRoute, to: SubnodeA())
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
