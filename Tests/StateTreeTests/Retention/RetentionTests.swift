import Emitter
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
    let tree = Tree.main
    var scopes: [WeakRef<NodeScope<DeepNode>>] = []
    let count = 800

    try ({
      let lifetime = try tree
        .start(root: DeepNode(depth: count))
      let rootScope = (try? lifetime.runtime.getScope(for: lifetime.rootID))?
        .underlying as? NodeScope<DeepNode>
      var maybeScope: NodeScope<DeepNode>? = rootScope
      while let scope = maybeScope {
        scopes.append(.init(ref: scope))
        maybeScope = scope.childScopes.filter { $0.id != scope.id }.first?
          .underlying as? NodeScope<DeepNode>
      }

      XCTAssertEqual(scopes.compactMap(\.ref).count, count)

      lifetime.dispose()
    })()
    XCTAssertEqual(scopes.compactMap(\.ref).count, 0)
  }
}

// MARK: RetentionTests.DeepNode

extension RetentionTests {

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
