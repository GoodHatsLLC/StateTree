import StateTree
import XCTest
@testable import TicTacToeDomain

// MARK: - GameNodeTests

final class GameNodeTests: XCTestCase {

  var tree: (any TreeType)?

  override func setUp() async throws { }

  override func tearDown() async throws {
    await tree?.stopIfActive()
  }

  @TreeActor
  func test_play_swapsPlayer() async throws {
    let player: Projection<Player> = .stored(.O)
    let tree = Tree(
      root: GameNode(currentPlayer: player, finishHandler: { _ in })
    )
    self.tree = tree
    try tree.start()
    let node = try tree.assume.rootNode
    XCTAssertEqual(node.currentPlayer, .O)
    node.play(row: 0, col: 0)
    XCTAssertEqual(node.currentPlayer, .X)
  }

}
