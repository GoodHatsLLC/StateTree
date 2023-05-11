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
    try! tree.start()
      .autostop()
      .stage(on: stage)
  }

  override func tearDown() {
    stage.reset()
  }

  func test_routeAccess() async throws {
    await tree.once.behaviorsStarted()
    let root = try tree.assume.rootNode

    XCTAssertEqual(55, root.single?.v1)
    XCTAssertEqual(nil, root.union2?.a?.v1)
    XCTAssertEqual(55, try tree.assume.rootNode.union2?.b?.v1)
    XCTAssertEqual(nil, try tree.assume.rootNode.union3?.a?.v1)
    XCTAssertEqual(nil, try tree.assume.rootNode.union3?.b?.v1)
    XCTAssertEqual(55, try tree.assume.rootNode.union3?.c?.v1)
    XCTAssertEqual(55, try tree.assume.rootNode.list?[1].v1)
    XCTAssertEqual(nil, try tree.assume.rootNode.list?.at(index: 100)?.v1)
    XCTAssertNotNil(try tree.assume.rootNode.union3?.c?.$v1 is Binding<Int>)
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
