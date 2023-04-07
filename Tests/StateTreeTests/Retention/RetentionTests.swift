import Disposable
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
    var scopes: [WeakRef<NodeScope<DeepNode>>] = []
    let count = 800

    try await ({
      let stage = DisposableStage()
      let tree = Tree(root: DeepNode(depth: count))
      await tree.run(on: stage)
      let rootID = try tree.rootID
      let rootScope = (try? tree.runtime.getScope(for: rootID))?
        .underlying as? NodeScope<DeepNode>
      var maybeScope: NodeScope<DeepNode>? = rootScope
      while let scope = maybeScope {
        scopes.append(.init(ref: scope))
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

    @Route(DeepNode.self) var next
    @Value var depth: Int

    var rules: some Rules {
      if depth > 1 {
        $next.route { DeepNode(depth: depth - 1) }
      }
    }
  }

}
