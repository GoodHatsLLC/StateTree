import Foundation
import StateTree

// MARK: - Authentication

public struct Authentication: TreeState {

  public init(
    playerX: String = "",
    playerO: String = "",
    token: String = ""
  ) {
    self.playerX = playerX
    self.playerO = playerO
    self.token = token
  }

  var playerX = ""
  var playerO = ""
  var token = ""

}

// MARK: - AuthError

struct AuthError: Error { }

// MARK: - AuthClient
