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
    XCTAssertNil(try tree.rootNode.route)
    try tree.rootNode.select = "a"
    XCTAssertNotNil(try tree.rootNode.route?.a)
    try tree.rootNode.select = "b"
    XCTAssertNotNil(try tree.rootNode.route?.b)
    try tree.rootNode.select = "bad"
    XCTAssertNil(try tree.rootNode.route)
  }

  @TreeActor
  func test_directNodeRoute_Union3() async throws {
    let tree = Tree(
        root: Union3Node()
      )
    XCTAssertNil(try tree.rootNode.route)
    try tree.rootNode.select = "a"
    XCTAssertNotNil(try tree.rootNode.route?.a)
    try tree.rootNode.select = "b"
    XCTAssertNotNil(try tree.rootNode.route?.b)
    try tree.rootNode.select = "c"
    XCTAssertNotNil(try tree.rootNode.route?.c)
    try tree.rootNode.select = "bad"
    XCTAssertNil(try tree.rootNode.route)
  }
}

extension UnionRouteWithoutEnumTests {

  // MARK: - UnionNode

  struct Union2Node: Node {
    @Value var select: String?
    @Route(NodeA.self, NodeB.self) var route
    var rules: some Rules {
      switch select {
      case "a":
        try $route.route(to: NodeA())
      case "b":
        try $route.route {
          NodeB()
        }
      default:
        try $route.route(to: BadNode())
      }
    }
  }

  struct Union3Node: Node {
    @Value var select: String?
    @Route(NodeA.self, NodeB.self, NodeC.self) var route
    var rules: some Rules {
      if select == "a" {
        try $route.route(to: NodeA())
      } else if select == "b" {
        try $route.route {
          NodeB()
        }
      }

      if select == "c" {
        try $route.route(to: NodeC())
      } else if select == "bad" {
        try $route.route(to: BadNode())
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
