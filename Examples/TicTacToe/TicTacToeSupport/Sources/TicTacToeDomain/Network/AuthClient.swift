import Foundation
import StateTree

// MARK: - AuthClientType

public protocol AuthClientType {
  func auth(playerX: String, playerO: String, password: String) async throws -> Authentication
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

// MARK: - AuthClientKey

struct AuthClientKey: DependencyKey {
  static let defaultValue: any AuthClientType = LiveAuthClient()
}

extension DependencyValues {
  public var authClient: any AuthClientType {
    get { self[AuthClientKey.self] }
    set { self[AuthClientKey.self] = newValue }
  }
}
