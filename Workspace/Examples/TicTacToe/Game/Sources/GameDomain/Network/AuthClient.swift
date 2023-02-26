import Foundation
import StateTree

// MARK: - AuthClientType

protocol AuthClientType {
  func auth(playerX: String, playerO: String, password: String) async throws -> Authentication
}

extension AuthClientType {
  public func erase() -> AuthClient {
    AuthClient(underlying: self)
  }
}

// MARK: - AuthClient

public struct AuthClient: AuthClientType, Sendable {
  init(underlying: some AuthClientType) {
    self.authFunc = { x, o, password in
      try await underlying.auth(playerX: x, playerO: o, password: password)
    }
  }

  public func auth(
    playerX: String,
    playerO: String,
    password: String
  ) async throws
    -> Authentication
  {
    try await authFunc(playerX, playerO, password)
  }

  private let authFunc: @Sendable (String, String, String) async throws -> Authentication
}

// MARK: - LiveAuthClient

struct LiveAuthClient: AuthClientType {
  init() { }
  func auth(playerX: String, playerO: String, password: String) async throws -> Authentication {
    try await Task.sleep(nanoseconds: NSEC_PER_SEC / 3)
    if password == "password" {
      return Authentication(playerX: playerX, playerO: playerO, token: UUID().uuidString)
    } else {
      throw AuthError()
    }
  }
}

// MARK: - AuthClientMock

struct AuthClientMock: AuthClientType {
  func auth(
    playerX _: String,
    playerO _: String,
    password _: String
  ) async throws
    -> Authentication
  {
    throw AuthError()
  }
}

// MARK: - AuthClientKey

struct AuthClientKey: DependencyKey {
  static let defaultValue: AuthClient = LiveAuthClient().erase()
}

extension DependencyValues {
  var authClient: AuthClient {
    get { self[AuthClientKey.self] }
    set { self[AuthClientKey.self] = newValue }
  }
}
