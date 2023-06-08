import StateTreeTesting
import XCTest
@testable import TicTacToeDomain

// MARK: - GameNodeTests

final class GameNodeTests: XCTestCase {

  let manager = TestTreeManager()

  override func setUp() async throws { }

  override func tearDown() async throws {
    manager.tearDown()
  }

  @TreeActor
  func test_play_swapsPlayer() async throws {
    let player: Projection<Player> = .stored(.O)
    @TestingTree var root = GameNode(currentPlayer: player, finishHandler: { _ in })
    try $root.start(with: manager)
    XCTAssertEqual(root.currentPlayer, .O)
    root.play(row: 0, col: 0)
    XCTAssertEqual(root.currentPlayer, .X)
  }

  @TreeActor
  func test_play_isAtomic() async throws {
    let player: Projection<Player> = .stored(.O)
    @TestingTree var root = GameNode(currentPlayer: player, finishHandler: { _ in })
    try $root.start(with: manager)
    _ = try $root.flushUpdateStats()
    root.play(row: 0, col: 0)
    let stats = try $root.flushUpdateStats()
    XCTAssertEqual(stats.counts.allNodeEvents, 1)
  }

  @TreeActor
  func test_win_firesFinishHandler() async throws {
    let player: Projection<Player> = .stored(.O)
    var result: GameResult? = nil
    @TestingTree var root = GameNode(currentPlayer: player, finishHandler: { result = $0 })
    try $root.start(with: manager)

    root.play(row: 0, col: 0)
    root.play(row: 1, col: 0)
    root.play(row: 0, col: 1)
    root.play(row: 1, col: 1)
    XCTAssertEqual(root.currentPlayer, .O)
    XCTAssertNil(result)
    root.play(row: 0, col: 2)
    XCTAssertEqual(result, .win(.O))
  }

}
