import Foundation
import StateTree

public struct AppNode: Node {

  public nonisolated init() { }

  @Value var authentication: Authentication?
  @Route public var gameOrSignIn: Union2<GameInfoNode, UnauthenticatedNode>? = nil

  public var rules: some Rules {
    if let auth = Projection($authentication) {
      $gameOrSignIn.serve {
        .a(GameInfoNode(authentication: auth, logoutFunc: { authentication = nil }))
      }
    } else {
      $gameOrSignIn.serve {
        .b(UnauthenticatedNode(authentication: $authentication))
      }
    }
  }
}
