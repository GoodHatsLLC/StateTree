import StateTree
import XCTest
@testable import TicTacToeDomain

// MARK: - AppNodeTests

final class AppNodeTests: XCTestCase {

  var tree: (any TreeType)?

  override func setUp() async throws { }

  override func tearDown() async throws {
    await tree?.stopIfActive()
  }

  @TreeActor
  func test_route_byAuthentication() async throws {
    let tree = Tree(
      root: AppNode()
    )
    self.tree = tree
    try tree.start()
    let node = try tree.assume.rootNode

    XCTAssertNil(node.authentication)
    XCTAssert(node.gameOrSignIn?.anyNode is UnauthenticatedNode)
    node.authentication = .init(playerX: "", playerO: "", token: "")
    XCTAssert(node.gameOrSignIn?.anyNode is GameInfoNode)
  }

}
