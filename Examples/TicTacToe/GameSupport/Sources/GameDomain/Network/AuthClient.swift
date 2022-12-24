import Foundation
import StateTree

// MARK: - AuthClient

public protocol AuthClient {
  func auth(name: String, password: String) async throws -> Authentication
}

// MARK: - AuthClientImpl

struct AuthClientImpl: AuthClient {
  public init() {}
  public func auth(name: String, password: String) async throws -> Authentication {
    if password == "Yolo123" {
      return Authentication(userName: name, token: UUID().uuidString)
    } else {
      throw AuthError()
    }
  }
}

// MARK: - AuthClientMock

struct AuthClientMock: AuthClient {
  func auth(name _: String, password _: String) async throws -> Authentication {
    throw AuthError()
  }
}

// MARK: - AuthClientKey

struct AuthClientKey: DependencyKey {
  static let defaultValue: any AuthClient = AuthClientMock()
}

extension DependencyValues {
  var authClient: any AuthClient {
    get { self[AuthClientKey.self] }
    set { self[AuthClientKey.self] = newValue }
  }
}
