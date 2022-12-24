import Foundation
import StateTree

// MARK: - Authentication

public struct Authentication: ModelState {
  public init(userName: String = "", token: String = "") {
    self.userName = userName
    self.token = token
  }

  var userName = ""
  var token = ""

}

// MARK: - AuthError

struct AuthError: Error {}

// MARK: - AuthClient
