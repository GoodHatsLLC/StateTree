import StateTree
import TicTacToeDomain
import XCTest

extension Returning where Value == Void {
  public static var void: Self {
    .init(Void.self)
  }
}

// MARK: - Returning

public struct Returning<Value> {

  // MARK: Lifecycle

  init(_: Value.Type) { }

  // MARK: Public

  public struct Failure: Error { }
  public struct Sync {
    public func success(_ value: Value) -> Value {
      value
    }

    public var throwing: Throwing { Throwing() }
    public struct Throwing {
      public func success(_ value: Value) throws -> Value {
        value
      }

      public func failure() throws -> Value {
        throw Failure()
      }

      public func failure(_ error: some Error) throws -> Value {
        throw error
      }
    }
  }

  public struct Async {
    public func success(_ value: Value) async -> Value { value }
    public var throwing: Throwing {
      Throwing()
    }

    public struct Throwing {
      public func success(_ value: Value) async throws -> Value {
        value
      }

      public func failure() async throws -> Value {
        throw Failure()
      }

      public func failure(_ error: some Error) async throws -> Value {
        throw error
      }
    }
  }

  public var sync: Sync { Sync() }
  public var async: Async { Async() }

  public static func type(_ type: Value.Type) -> Returning<Value> {
    .init(type)
  }

}

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
      configuration: .init(behaviorTracker: .init(behaviorInterceptors: [
        .init(id: .id("auth"), behavior: Behaviors.make {
          try await Returning.type(Authentication.self).async.throwing
            .success(payload)
        }),
      ]))
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
      configuration: .init(behaviorTracker: .init(behaviorInterceptors: [
        .init(id: .id("auth"), behavior: Behaviors.make {
          try await Returning.void.async.throwing
            .failure()
        }),
      ]))
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
}
