import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - ProjectionTests

final class ProjectionTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_projection() async throws {
    let tree = Tree(root: ProjectionHost())
    try tree.start()
    let node = try tree.assume.rootNode
    XCTAssertNil(node.route)
    node.val = 3
    let subnode = try XCTUnwrap(node.route?.c)
    subnode.value = -1
    XCTAssertNil(node.route)
  }

  @TreeActor
  func test_projection_onChange() async throws {
    let tree = Tree(root: ReferencedHost(intVal: 5))
    try tree.start()
    let node = try tree.assume.rootNode

    XCTAssertEqual(node.intVal, 5)
    XCTAssertEqual(node.displayed?.intVal, 5)
    XCTAssertEqual(node.displayed?.derived, -5)

    node.intVal = 3

    XCTAssertEqual(node.intVal, 3)
    XCTAssertEqual(node.displayed?.intVal, 3)
    XCTAssertEqual(node.displayed?.derived, -3)
  }
}

extension ProjectionTests {

  // MARK: - ProjectionHost

  struct ProjectionHost: Node {

    @Route var route: Union.Three<SubnodeA, SubnodeB, SubnodeC>? = nil
    @Value var val: Int?

    var rules: some Rules {
      switch val {
      case 1:
        Serve(.a(.init()), at: $route)
      case 2:
        Serve(.b(.init()), at: $route)
      case 3:
        Serve(.c(SubnodeC(value: $val)), at: $route)
      default:
        ()
      }
    }
  }

  // MARK: - SubnodeA

  struct SubnodeA: Node {
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

  // MARK: - DisplayedReference

  struct DisplayedReference: Node {
    @Projection var intVal: Int
    @Value var derived = 0
    var rules: some Rules {
      OnUpdate(intVal) { value in
        derived = -value
      }
    }
  }

  // MARK: - ReferencedHost

  struct ReferencedHost: Node {
    @Value var intVal: Int
    @Route var displayed: DisplayedReference? = nil
    var rules: some Rules {
      Serve(DisplayedReference(intVal: $intVal), at: $displayed)
    }
  }

}
