#if !CUSTOM_ACTOR
import Disposable
import SwiftUI
import XCTest
@_spi(Implementation) @testable import StateTree
@_spi(Implementation) @testable import StateTreeSwiftUI

// MARK: - NodeContextAccess

@MainActor
final class NodeContextAccess: XCTestCase {

  let stage = DisposableStage()
  var tree: Tree<Parent> = .init(root: Parent())

  override func setUp() {
    tree = Tree(
      root: Parent()
    )
  }

  override func tearDown() {
    stage.reset()
  }

  func test_routeAccess() async throws {
    let context = try await TreeNode(scope: tree.awaitStarted().root)
    XCTAssertEqual(55, context.$single?.v1)
    XCTAssertEqual(nil, context.$union2.a?.v1)
    XCTAssertEqual(55, context.$union2.b?.v1)
    XCTAssertEqual(nil, context.$union3.a?.v1)
    XCTAssertEqual(nil, context.$union3.b?.v1)
    XCTAssertEqual(55, context.$union3.c?.v1)
    XCTAssertEqual(55, context.$list[1].v1)
    XCTAssertEqual(nil, context.$list.at(index: 100)?.v1)
    XCTAssertNotNil(context.$union3.c?.$v1 is Binding<Int>)
  }
}

extension NodeContextAccess {

  struct ChildOne: Node {
    @Projection var v1: Int
    var rules: some Rules { () }
  }

  struct ChildTwo: Node, Identifiable {
    let id: Int
    @Projection var v1: Int
    var rules: some Rules { () }
  }

  struct ChildThree: Node {
    @Projection var v1: Int
    var rules: some Rules { () }
  }

  struct Parent: Node {
    @Value var v1: Int = 55
    @Route(ChildOne.self) var single
    @Route(ChildOne.self, ChildTwo.self) var union2
    @Route(ChildOne.self, ChildTwo.self, ChildThree.self) var union3
    @Route([ChildTwo].self) var list

    var rules: some Rules {
      $single.route {
        ChildOne(v1: $v1)
      }
      try $union2.route(to: ChildTwo(id: 1, v1: $v1))
      $union3.route(
        to: .c(.init(v1: $v1))
      )
      $list.route(
        to: [
          .init(id: 1, v1: $v1),
          .init(id: 2, v1: $v1),
          .init(id: 3, v1: $v1),
          .init(id: 4, v1: $v1),
        ]
      )
    }
  }

}
#endif
