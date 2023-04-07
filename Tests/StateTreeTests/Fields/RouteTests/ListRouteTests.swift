import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - ListRouteTests

final class ListRouteTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_listRoute() async throws {
    let lifetime = try Tree_REMOVE.main
      .start(
        root: ListNode()
      )
    lifetime.stage(on: stage)

    XCTAssertNil(lifetime.rootNode.route)

    var sorted: [String] = []
    var nodes: [NodeA] = []

    func assertAfter(_ nums: [Int]) {
      sorted = nums.map { String($0) }
      lifetime.rootNode.numbers = nums
      nodes = lifetime.rootNode.route ?? []
      XCTAssertEqual(nodes.map(\.idStr), sorted)
    }

    assertAfter(Array(0 ..< 100))
    assertAfter(Array(0 ..< 20))
    assertAfter(Array(5 ..< 15))
    lifetime.rootNode.numbers = (Array(10 ..< 15) + Array(20 ..< 30))
    nodes = try XCTUnwrap(lifetime.rootNode.route)
    XCTAssertEqual(
      nodes.map(\.idStr),
      ["20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "10", "11", "12", "13", "14"]
    )
    XCTAssertEqual(nodes.count, 15)
    lifetime.rootNode.numbers! += Array(1000 ..< 2000)
    XCTAssertEqual(lifetime.rootNode.numbers?.count, 1015)
  }
}

extension ListRouteTests {

  // MARK: - ListNode

  struct ListNode: Node {
    @Value var numbers: [Int]? = nil
    @Route([NodeA].self) var route
    var rules: some Rules {
      if let numbers {
        let nodes = numbers.map { id in
          NodeA(id: id)
        }
        $route.route(to: nodes)
      }
    }
  }

  // MARK: - NodeA

  struct NodeA: Node, Identifiable {
    let id: Int
    var idStr: String { String(id) }
    var rules: some Rules { .none }
  }
}
