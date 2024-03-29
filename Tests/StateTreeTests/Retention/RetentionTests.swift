import Disposable
import Emitter
import TreeActor
import Utilities
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - RetentionTests

final class RetentionTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_retention() async throws {
    var scopes: [WeakRef<NodeScope<DeepNode>>] = []
    let count = 800

    try ({
      let stage = DisposableStage()
      let tree = Tree(root: DeepNode(depth: count))
      let handle = try tree.start()
      handle.autostop()
        .stage(on: stage)
      let rootScope = try tree.assume.root
      var maybeScope: NodeScope<DeepNode>? = rootScope
      while let scope = maybeScope {
        scopes.append(.init(scope))
        maybeScope = scope.childScopes.filter { $0.nid != scope.nid }.first?
          .underlying as? NodeScope<DeepNode>
      }

      XCTAssertEqual(scopes.compactMap(\.ref).count, count)

      stage.dispose()
    })()
    XCTAssertEqual(scopes.compactMap(\.ref).count, 0)
  }
}

// MARK: RetentionTests.DeepNode

extension RetentionTests {

  struct DeepNode: Node {

    @Route var next: DeepNode? = nil
    @Value var depth: Int

    var rules: some Rules {
      if depth > 1 {
        Serve(DeepNode(depth: depth - 1), at: $next)
      }
    }
  }

}
