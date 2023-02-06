import Foundation
import StateTree

// MARK: - AuthClient

protocol AuthClient {
  func auth(playerX: String, playerO: String, password: String) async throws -> Authentication
}

// MARK: - LiveAuthClient

struct LiveAuthClient: AuthClient {
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

struct AuthClientMock: AuthClient {
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
  static let defaultValue: any AuthClient = LiveAuthClient()
}

extension DependencyValues {
  var authClient: any AuthClient {
    get { self[AuthClientKey.self] }
    set { self[AuthClientKey.self] = newValue }
  }
}
