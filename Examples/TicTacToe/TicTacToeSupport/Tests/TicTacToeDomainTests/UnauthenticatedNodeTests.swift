import StateTree
import TicTacToeDomain
import XCTest

// MARK: - UnauthenticatedNodeTests

final class UnauthenticatedNodeTests: XCTestCase {

  var tree: (any TreeType)?

  override func setUp() async throws { }

  override func tearDown() async throws {
    await tree?.stopIfActive()
  }

  @TreeActor
  func test_authSuccess() async throws {
    let auth: Projection<Authentication?> = .stored(nil)
    let payload = Authentication(playerX: "XXX", playerO: "OOO", token: "token")
    let tree = Tree(
      root: UnauthenticatedNode(authentication: auth),
      interceptors: [
        .init(id: .id("auth"), replacement: Behaviors.make {
          let fn: () async throws -> Authentication = { payload }
          return try await fn()
        }),
      ]
    )
    self.tree = tree
    try tree.start()
    let node = try tree.assume.rootNode
    XCTAssertEqual(node.isLoading, false)
    XCTAssertEqual(node.shouldHint, false)
    XCTAssertEqual(auth.value, nil)
    node.authenticate(playerX: "", playerO: "", password: "")
    XCTAssertEqual(node.isLoading, true)
    XCTAssertEqual(node.shouldHint, false)
    XCTAssertEqual(auth.value, nil)
    try await tree.behaviorTracker.awaitBehaviors()
    XCTAssertEqual(node.isLoading, false)
    XCTAssertEqual(node.shouldHint, false)
    XCTAssertEqual(auth.value, payload)
  }

  @TreeActor
  func test_authFailure() async throws {
    let auth: Projection<Authentication?> = .stored(nil)
    let tree = Tree(
      root: UnauthenticatedNode(authentication: auth),
      interceptors: [
        .init(id: .id("auth"), replacement: Behaviors.make {
          let fn: () async throws -> Authentication = { throw TestFail() }
          return try await fn()
        }),
      ]
    )
    self.tree = tree
    try tree.start()
    let node = try tree.assume.rootNode
    XCTAssertEqual(node.isLoading, false)
    XCTAssertEqual(node.shouldHint, false)
    XCTAssertEqual(auth.value, nil)
    node.authenticate(playerX: "", playerO: "", password: "")
    XCTAssertEqual(node.isLoading, true)
    XCTAssertEqual(node.shouldHint, false)
    XCTAssertEqual(auth.value, nil)
    try await tree.behaviorTracker.awaitBehaviors()
    XCTAssertEqual(node.isLoading, false)
    XCTAssertEqual(node.shouldHint, true)
    XCTAssertEqual(auth.value, nil)
  }

  @TreeActor
  func test_authValues() async throws {
    let auth: Projection<Authentication?> = .stored(nil)
    var didCall = false
    let mock = AuthClientMock { playerX, playerO, password in
      XCTAssertEqual(playerX, "px")
      XCTAssertEqual(playerO, "po")
      XCTAssertEqual(password, "pass")
      didCall = true
      throw TestFail()
    }
    let tree = Tree(
      root: UnauthenticatedNode(authentication: auth),
      dependencies: .defaults.inject(\.authClient, value: mock)
    )
    self.tree = tree
    try tree.start()
    let node = try tree.assume.rootNode

    XCTAssertFalse(didCall)
    node.authenticate(playerX: "px", playerO: "po", password: "pass")
    try await tree.behaviorTracker.awaitBehaviors()
    XCTAssert(didCall)
  }
}

extension UnauthenticatedNodeTests {
  // MARK: - AuthClientMock

  struct AuthClientMock: AuthClientType {
    let authCallback: (
      _ playerX: String,
      _ playerO: String,
      _ password: String
    ) throws -> Authentication
    func auth(
      playerX: String,
      playerO: String,
      password: String
    ) async throws
      -> Authentication
    {
      try authCallback(playerX, playerO, password)
    }
  }

  struct TestFail: Error { }

}
