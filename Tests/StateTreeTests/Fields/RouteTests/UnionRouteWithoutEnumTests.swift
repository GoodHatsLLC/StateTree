import Disposable
@_spi(Implementation) import StateTree
import XCTest

// MARK: - UnionRouteWithoutEnumTests

final class UnionRouteWithoutEnumTests: XCTestCase {

  @TreeActor
  func test_directNodeRoute_Union2() async throws {
    let tree = Tree(
      root: Union2Node()
    )
    try tree.start()
    XCTAssertNil(try tree.assume.rootNode.route)
    try tree.assume.rootNode.select = "a"
    XCTAssertNotNil(try tree.assume.rootNode.route?.a)
    try tree.assume.rootNode.select = "b"
    XCTAssertNotNil(try tree.assume.rootNode.route?.b)
    try tree.assume.rootNode.select = "bad"
    XCTAssertNil(try tree.assume.rootNode.route)
    try tree.stop()
  }

  @TreeActor
  func test_directNodeRoute_Union3() async throws {
    let tree = Tree(
      root: Union3Node()
    )
    try tree.start()
    XCTAssertNil(try tree.assume.rootNode.route)
    try tree.assume.rootNode.select = "a"
    XCTAssertNotNil(try tree.assume.rootNode.route?.a)
    try tree.assume.rootNode.select = "b"
    XCTAssertNotNil(try tree.assume.rootNode.route?.b)
    try tree.assume.rootNode.select = "c"
    XCTAssertNotNil(try tree.assume.rootNode.route?.c)
    try tree.assume.rootNode.select = "bad"
    XCTAssertNil(try tree.assume.rootNode.route)
    try tree.stop()
  }
}

extension UnionRouteWithoutEnumTests {

  // MARK: - UnionNode

  struct Union2Node: Node {
    @Value var select: String?
    @Route var route: Union.Two<NodeA, NodeB>? = nil
    var rules: some Rules {
      switch select {
      case "a":
        Attach($route, to: .a(.init()))
      case "b":
        Attach($route, to: .b(.init()))
      default:
        .none
      }
    }
  }

  struct Union3Node: Node {
    @Value var select: String?
    @Route var route: Union.Three<NodeA, NodeB, NodeC>? = nil
    var rules: some Rules {
      if select == "a" {
        Attach($route, to: .a(.init()))
      } else if select == "b" {
        Attach($route, to: .b(.init()))
      }

      if select == "c" {
        Attach($route, to: .c(.init()))
      } else if select == "bad" {
        .none
      }
    }
  }

  struct BadNode: Node {
    var rules: some Rules { .none }
  }

  // MARK: - NodeA

  struct NodeA: Node {
    var rules: some Rules { .none }
  }

  // MARK: - NodeB

  struct NodeB: Node {
    var rules: some Rules { .none }
  }

  // MARK: - NodeB

  struct NodeC: Node {
    var rules: some Rules { .none }
  }

  struct NodeD: Node {
    var rules: some Rules { .none }
  }
}
