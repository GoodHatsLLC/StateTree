import Disposable
import Emitter
import TreeActor
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - RoutingInitializationTests

final class RoutingInitializationTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_structuralReinitQuirk() async throws {
    let tree = Tree(root: DeepValueNode(depth: 3))

    try tree.start()
      .autostop()
      .stage(on: stage)

    XCTAssertEqual(4, try tree.assume.info.height)

    try tree.assume.rootNode.depth = 0
    XCTAssertEqual(1, try tree.assume.info.height)

    try tree.assume.rootNode.depth = 10
    XCTAssertEqual(11, try tree.assume.info.height)

    // We fail to reinit because structural identity matches
    try tree.assume.rootNode.depth = 15
    XCTAssertEqual(11, try tree.assume.info.height)

    stage.dispose()
  }

}

// MARK: RoutingInitializationTests.DeepValueNode

extension RoutingInitializationTests {

  struct DeepValueNode: Node {

    @Route(DeepValueNode.self) var next
    @Route(DeepValueNode.self) var always
    @Value var depth: Int

    var rules: some Rules {
      if depth > 1 {
        $next.route { DeepValueNode(depth: depth - 1) }
      }
      if depth > 0 {
        $always.route {
          DeepValueNode(depth: 0)
        }
      }
    }
  }

}
