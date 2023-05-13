import StateTree
import XCTest
@testable import TicTacToeDomain

// MARK: - GameInfoNodeTests

final class GameInfoNodeTests: XCTestCase {

  var tree: (any TreeType)?

  override func setUp() async throws { }

  override func tearDown() async throws {
    await tree?.stopIfActive()
  }

  @TreeActor
  func test_logOutCallback_called() async throws {
    var didLogOut = false
    let tree = Tree(
      root: GameInfoNode(
        authentication: .stored(
          .init(playerX: "xxx", playerO: "ooo", token: "token")
        ),
        logoutFunc: {
          didLogOut = true
        }
      )
    )
    self.tree = tree
    try tree.start()
    let node = try tree.assume.rootNode
    XCTAssertEqual(didLogOut, false)
    node.logout()
    XCTAssertEqual(didLogOut, true)
  }

}
