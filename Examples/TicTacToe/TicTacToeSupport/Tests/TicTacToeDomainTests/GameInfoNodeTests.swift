import StateTreeTesting
import XCTest
@testable import TicTacToeDomain

// MARK: - GameInfoNodeTests

final class GameInfoNodeTests: XCTestCase {

  let manager = TestTreeManager()
  var auth: Projection<Authentication>!

  override func setUp() async throws {
    auth = .stored(
      .init(playerX: "xxx", playerO: "ooo", token: "token")
    )
  }

  override func tearDown() async throws {
    manager.tearDown()
  }

  @TreeActor
  func test_logOutCallback_called_onLogOut() async throws {
    var didLogOut = false
    @TestingTree var root = GameInfoNode(
      authentication: auth,
      logoutFunc: {
        didLogOut = true
      }
    )
    try $root.start(with: manager)

    XCTAssertEqual(didLogOut, false)
    root.logout()
    XCTAssertEqual(didLogOut, true)
  }

  @TreeActor
  func test_activePlayerSet_onInitialGameStart() async throws {
    @TestingTree var root = GameInfoNode(authentication: auth, logoutFunc: { })
    try $root.start(with: manager)

    XCTAssertNil(root.activePlayer)
    root.startGame()
    XCTAssertNotNil(root.activePlayer)
  }

  @TreeActor
  func test_activePlayerSwapped_onGameStart() async throws {
    @TestingTree var root = GameInfoNode(authentication: auth, logoutFunc: { })
    try $root.start(with: manager)
    root.startGame()

    let initial = try XCTUnwrap(root.activePlayer)
    root.startGame()
    let swapped = try XCTUnwrap(root.activePlayer)

    XCTAssertNotEqual(initial, swapped)
  }

}
