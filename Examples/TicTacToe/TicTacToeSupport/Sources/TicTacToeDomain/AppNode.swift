import Foundation
import StateTree

public struct AppNode: Node {

  public nonisolated init() { }

  @Value private var authentication: Authentication?
  @Route(GameInfoNode.self, UnauthenticatedNode.self) public var gameOrSignIn

  public var rules: some Rules {
    if let auth = $authentication.compact() {
      $gameOrSignIn.route {
        .a(
          GameInfoNode(authentication: auth) {
            authentication = nil
          }
        )
      }
    } else {
      $gameOrSignIn.route {
        .b(
          UnauthenticatedNode(
            authentication: $authentication
          )
        )
      }
    }
  }
}
