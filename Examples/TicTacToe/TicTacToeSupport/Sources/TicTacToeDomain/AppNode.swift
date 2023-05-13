import Foundation
import StateTree

public struct AppNode: Node {

  public nonisolated init() { }

  @Value var authentication: Authentication?
  @Route(GameInfoNode.self, UnauthenticatedNode.self) public var gameOrSignIn

  public var rules: some Rules {
    if let auth = $authentication.compact() {
      try $gameOrSignIn.route {
        GameInfoNode(authentication: auth) {
          authentication = nil
        }
      }
    } else {
      try $gameOrSignIn.route {
        UnauthenticatedNode(authentication: $authentication)
      }
    }
  }
}
