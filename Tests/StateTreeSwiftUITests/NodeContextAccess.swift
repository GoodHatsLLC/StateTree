#if !CUSTOM_ACTOR
import Disposable
import SwiftUI
import XCTest
@_spi(Implementation) import StateTree
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
    XCTAssertEqual(55, try tree.assume.rootNode.list[1].v1)
    XCTAssertEqual(nil, try tree.assume.rootNode.list.at(index: 100)?.v1)
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
    @Route var single: ChildOne? = nil
    @Route var union2: Union.Two<ChildOne, ChildTwo>? = nil
    @Route var union3: Union.Three<ChildOne, ChildTwo, ChildThree>? = nil
    @Route var list: [ChildTwo] = []

    var rules: some Rules {
      Serve(
        ChildOne(v1: $v1),
        at: $single
      )
      Serve(.b(ChildTwo(id: 1, v1: $v1)), at: $union2)
      Serve(.c(ChildThree(v1: $v1)), at: $union3)
      Serve(data: Array(0 ..< 5), at: $list) {
        .init(id: $0, v1: $v1)
      }
    }
  }

}
#endif
