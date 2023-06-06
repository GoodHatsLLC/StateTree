#if !CUSTOM_ACTOR
import Disposable
import SwiftUI
import XCTest
@_spi(Implementation) import StateTree
@testable import StateTreeSwiftUI

@MainActor
final class BindingAccess: XCTestCase {

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

  func test_bindingAccess() async throws {
    let scope = try tree.assume.root
    @TreeNode var root: Parent
    _root = TreeNode(scope: scope)

    @TreeNode var subNode: Child
    _subNode = $root.$single
    XCTAssertNotNil($subNode.$v0 as Binding<Int>)
    XCTAssertNotNil($subNode.$v1 as Binding<Int>)
  }
}

extension BindingAccess {

  struct Child: Node {
    @Value var v0: Int = 0
    @Projection var v1: Int
    var rules: some Rules { () }
  }

  struct Parent: Node {
    @Route var single: Child = .init(v1: .constant(1))
    var rules: some Rules {
      ()
    }
  }

}
#endif
