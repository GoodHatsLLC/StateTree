#if !CUSTOM_ACTOR
import Disposable
import SwiftUI
import XCTest
@_spi(Implementation) import StateTree
@testable import StateTreeSwiftUI

@MainActor
final class RouteAccess: XCTestCase {

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
    let scope = try tree.assume.root
    @TreeNode var root: Parent
    _root = TreeNode(scope: scope)
    XCTAssertEqual(55, root.single?.v1)
    XCTAssertEqual(nil, root.union2?.a?.v1)
    XCTAssertEqual(55, root.union2?.b?.v1)
    XCTAssertEqual(nil, root.union3?.a?.v1)
    XCTAssertEqual(nil, root.union3?.b?.v1)
    XCTAssertEqual(55, root.union3?.c?.v1)
    XCTAssertEqual(55, root.list[1].v1)
    XCTAssertEqual(nil, root.list.at(index: 100)?.v1)
  }
}

extension RouteAccess {

  struct ChildOne: Node {
    @Value var v0: Int = 0
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
    @Value var v2: Int = 22
    var rules: some Rules { () }
  }

  struct Parent: Node {
    @Value var v1: Int = 55
    @Route var single: ChildOne? = nil
    @Route var union2: Union2<ChildOne, ChildTwo>? = nil
    @Route var union3: Union3<ChildOne, ChildTwo, ChildThree>? = nil
    @Route var list: [ChildTwo] = []

    var rules: some Rules {
      $single.serve { ChildOne(v1: $v1) }
      $union2.serve { .b(ChildTwo(id: 1, v1: $v1)) }
      $union3.serve { .c(ChildThree(v1: $v1)) }
      $list.serve(data: Array(0 ..< 5), identifiedBy: \.self) {
        .init(id: $0, v1: $v1)
      }
    }
  }

}
#endif
