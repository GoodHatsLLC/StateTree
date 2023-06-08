import Disposable
import StateTreeImperativeUI
import TreeActor
import XCTest

// MARK: - EventTests

@TreeActor
final class EventTests: XCTestCase {

  func test_startStop() async throws {
    let tree = try ReportedTree(tree: Tree(root: Parent()))
    @Reported var root: Parent
    _root = tree.root
    var rootDidStopCount = 0
    $root.onStop(subscriber: self) {
      rootDidStopCount += 1
    }
    XCTAssertEqual(rootDidStopCount, 0)
    try tree.stop()
    XCTAssertEqual(rootDidStopCount, 1)
  }

  func test_update() async throws {
    let tree = try ReportedTree(
      tree: Tree(
        root: Parent()
      )
    )
    @Reported var root: Parent
    _root = tree.root
    var rootFireCount = 0
    $root.onChange(subscriber: self) {
      rootFireCount += 1
    }
    XCTAssert(rootFireCount == 0)
    root.v1 = 1
    XCTAssertEqual(rootFireCount, 1)
    root.v1 = 3
    XCTAssertEqual(rootFireCount, 2)
  }

  func test_childUpdates() async throws {
    let tree = try ReportedTree(tree: Tree(root: Parent()))
    @Reported var root: Parent
    _root = tree.root

    var emitCount = 0

    $root.$single.onChange(subscriber: self) {
      emitCount += 1
    }

    $root.$union2?.b?.onChange(subscriber: self) {
      emitCount += 1
    }

    $root.$union3?.c?.onChange(subscriber: self) {
      emitCount += 1
    }

    for node in $root.$list {
      node.onChange(subscriber: self) {
        emitCount += 1
      }
    }

    XCTAssertEqual(emitCount, 0)

    let count = 3 + $root.$list.count

    root.v1 = 1

    XCTAssertEqual(emitCount, count)

    root.v1 = 3

    XCTAssertEqual(emitCount, count * 2)
  }
}

extension EventTests {

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
    @Route var single: ChildOne = .init(v1: .constant(1))
    @Route var maybeSingle: ChildOne? = nil
    @Route var union2: Union.Two<ChildOne, ChildTwo>? = nil
    @Route var union3: Union.Three<ChildOne, ChildTwo, ChildThree>? = nil
    @Route var list: [ChildTwo] = []

    var rules: some Rules {
      Serve(ChildOne(v1: $v1), at: $single)
      Serve(.b(ChildTwo(id: 1, v1: $v1)), at: $union2)
      Serve(.c(ChildThree(v1: $v1)), at: $union3)

      Serve(data: [1, 2, 3, 4], at: $list) { datum in
        .init(id: datum, v1: $v1)
      }
    }
  }

}
