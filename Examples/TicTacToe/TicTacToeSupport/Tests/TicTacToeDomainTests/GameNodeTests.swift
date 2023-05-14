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

  @TreeActor
  func test_play_isAtomic() async throws {
    let player: Projection<Player> = .stored(.O)
    let tree = Tree(
      root: GameNode(currentPlayer: player, finishHandler: { _ in })
    )
    self.tree = tree
    try tree.start()
    let node = try tree.assume.rootNode
    _ = try tree.assume.info.flushUpdateStats()
    node.play(row: 0, col: 0)
    let stats = try tree.assume.info.flushUpdateStats()
    XCTAssertEqual(stats.counts.allNodeEvents, 1)
  }

  @TreeActor
  func test_win_firesFinishHandler() async throws {
    let player: Projection<Player> = .stored(.O)
    var result: GameResult? = nil
    let tree = Tree(
      root: GameNode(currentPlayer: player, finishHandler: { result = $0 })
    )
    self.tree = tree
    try tree.start()
    let node = try tree.assume.rootNode
    node.play(row: 0, col: 0)
    node.play(row: 1, col: 0)
    node.play(row: 0, col: 1)
    node.play(row: 1, col: 1)
    XCTAssertEqual(node.currentPlayer, .O)
    XCTAssertNil(result)
    node.play(row: 0, col: 2)
    XCTAssertEqual(result, .win(.O))
  }

}
