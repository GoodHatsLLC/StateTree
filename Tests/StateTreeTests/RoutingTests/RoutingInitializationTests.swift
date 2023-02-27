import Emitter
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
    let testTree = Tree.main

    XCTAssertEqual(0, testTree._info?.depth ?? 0)

    let lifetime = try testTree
      .start(root: DeepValueNode(depth: 3))

    XCTAssertEqual(3, testTree._info?.depth)

    lifetime.rootNode.depth = 0
    XCTAssertEqual(0, testTree._info?.depth)

    lifetime.rootNode.depth = 10
    XCTAssertEqual(10, testTree._info?.depth)

    // We fail to reinit because structural identity matches
    lifetime.rootNode.depth = 15
    XCTAssertEqual(10, testTree._info?.depth)

    lifetime.dispose()

    XCTAssertEqual(0, testTree._info?.depth ?? 0)
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
