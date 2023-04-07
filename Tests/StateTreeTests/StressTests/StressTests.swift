import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - StressTests

final class StressTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_creationThrash() async throws {
    let testTree = Tree(root: DeepNode(depth: 1))

    let desiredDepth = 800
    let repetitions = 4

    func findDepth(from node: DeepNode) -> Int {
      1 + (node.next.map { findDepth(from: $0) } ?? 0)
    }

    func getDeepest(from node: DeepNode) -> DeepNode {
      node.next.map { getDeepest(from: $0) } ?? node
    }

    await testTree.run(on: stage)
    XCTAssert(try testTree.info.isActive == true)

    let initialSnapshot = try testTree.snapshot()

    let node = try testTree.root.node

    node.depth = desiredDepth
    XCTAssertEqual(findDepth(from: node), desiredDepth)

    let deepest = getDeepest(from: node)
    XCTAssertEqual(deepest.depth, 1)

    for _ in 0 ..< repetitions {
      node.depth = 1
      XCTAssertEqual(findDepth(from: node), 1)

      node.depth = desiredDepth
      XCTAssertEqual(findDepth(from: node), desiredDepth)
    }

    let depthSnapshot = try testTree.snapshot()
    XCTAssertNotEqual(initialSnapshot, depthSnapshot)

    node.depth = 1
    let finalSnapshot = try testTree.snapshot()

    XCTAssertEqual(initialSnapshot, finalSnapshot)
    XCTAssert(try testTree.info.isActive == true)
  }
}

// MARK: StressTests.DeepNode

extension StressTests {

  struct DeepNode: Node {

    @Route(DeepNode.self) var next
    @Value var depth: Int

    var rules: some Rules {
      if depth > 1 {
        $next.route { DeepNode(depth: depth - 1) }
      }
    }
  }

}
