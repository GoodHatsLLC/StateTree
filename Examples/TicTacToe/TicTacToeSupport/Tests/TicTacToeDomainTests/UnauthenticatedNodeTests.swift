import StateTreeTesting
import TicTacToeDomain
import XCTest

// MARK: - UnauthenticatedNodeTests

final class UnauthenticatedNodeTests: XCTestCase {

  let manager = TestTreeManager()

  override func setUp() async throws { }

  override func tearDown() async throws {
    manager.tearDown()
  }

  @TreeActor
  func test_authSuccess() async throws {
    let auth: Projection<Authentication?> = .stored(nil)
    let payload = Authentication(playerX: "XXX", playerO: "OOO", token: "token")
    @TestingTree var root = UnauthenticatedNode(authentication: auth)
    $root.interceptors = [
      .init(
        id: .id("auth"),
        replacement: Behaviors.make {
          let fn: () async throws -> Authentication = { payload }
          return try await fn()
        }
      ),
    ]
    try $root.start(with: manager)
    XCTAssertEqual(root.isLoading, false)
    XCTAssertEqual(root.shouldHint, false)
    XCTAssertEqual(auth.value, nil)
    root.authenticate(playerX: "", playerO: "", password: "")
    XCTAssertEqual(root.isLoading, true)
    XCTAssertEqual(root.shouldHint, false)
    XCTAssertEqual(auth.value, nil)
    try await $root.awaitBehaviors()
    XCTAssertEqual(root.isLoading, false)
    XCTAssertEqual(root.shouldHint, false)
    XCTAssertEqual(auth.value, payload)
  }

  @TreeActor
  func test_authFailure() async throws {
    let auth: Projection<Authentication?> = .stored(nil)
    @TestingTree var root = UnauthenticatedNode(authentication: auth)
    $root.interceptors = [
      .init(id: .id("auth"), replacement: Behaviors.make {
        let fn: () async throws -> Authentication = { throw TestFail() }
        return try await fn()
      }),
    ]
    try $root.start(with: manager)
    XCTAssertEqual(root.isLoading, false)
    XCTAssertEqual(root.shouldHint, false)
    XCTAssertEqual(auth.value, nil)
    root.authenticate(playerX: "", playerO: "", password: "")
    XCTAssertEqual(root.isLoading, true)
    XCTAssertEqual(root.shouldHint, false)
    XCTAssertEqual(auth.value, nil)
    try await $root.awaitBehaviors()
    XCTAssertEqual(root.isLoading, false)
    XCTAssertEqual(root.shouldHint, true)
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
    @TestingTree var root = UnauthenticatedNode(authentication: auth)
    $root.dependencies.inject(\.authClient, value: mock)

    try $root.start(with: manager)

    XCTAssertFalse(didCall)
    root.authenticate(playerX: "px", playerO: "po", password: "pass")
    try await $root.awaitBehaviors()
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
