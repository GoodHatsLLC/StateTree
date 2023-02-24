import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - ProjectionTests

@TreeActor
final class ProjectionTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  func test_projection() throws {
    let tree = try Tree.main
      .start(root: ProjectionHost())
    tree.stage(on: stage)
    let node = tree.rootNode
    XCTAssertNil(node.route)
    node.val = 3
    let subnode = try XCTUnwrap(node.route?.c)
    subnode.value = -1
    XCTAssertNil(node.route)
  }

  func test_projection_onChange() throws {
    let tree = try Tree.main
      .start(root: ReferencedHost(intVal: 5))
    tree.stage(on: stage)
    let node = tree.rootNode

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

    @Route(SubnodeA.self, SubnodeB.self, SubnodeC.self) var route
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
      OnChange(intVal) { value in
        derived = -value
      }
    }
  }

  // MARK: - ReferencedHost

  struct ReferencedHost: Node {
    @Value var intVal: Int
    @Route(DisplayedReference.self) var displayed
    var rules: some Rules {
      $displayed.route { DisplayedReference(intVal: $intVal) }
    }
  }

}
