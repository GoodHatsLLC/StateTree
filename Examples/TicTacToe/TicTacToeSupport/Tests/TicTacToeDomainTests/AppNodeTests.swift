import StateTreeTesting
import XCTest
@testable import TicTacToeDomain

// MARK: - AppNodeTests

final class AppNodeTests: XCTestCase {

  var manager = TestTreeManager()

  override func setUp() async throws { }

  override func tearDown() async throws {
    manager.tearDown()
  }

  @TreeActor
  func test_route_byAuthentication() async throws {
    @TestingTree var root = AppNode()

    try $root.start(with: manager)

    XCTAssertNil(root.authentication)
    XCTAssert(root.gameOrSignIn?.anyNode is UnauthenticatedNode)
    root.authentication = .init(playerX: "", playerO: "", token: "")
    XCTAssert(root.gameOrSignIn?.anyNode is GameInfoNode)
  }

}
