import Foundation
import StateTree

// MARK: - Authentication

public struct Authentication: Codable, Hashable {

  public init(
    playerX: String?,
    playerO: String?,
    token: String
  ) {
    self.playerX = (playerX ?? "").isEmpty ? "???" : "\(playerX ?? "")"
    self.playerO = (playerO ?? "").isEmpty ? "???" : "\(playerO ?? "")"
    self.token = token
  }

  var playerX: String
  var playerO: String
  var token = ""

}

// MARK: - AuthError

struct AuthError: Error { }

// MARK: - AuthClient
