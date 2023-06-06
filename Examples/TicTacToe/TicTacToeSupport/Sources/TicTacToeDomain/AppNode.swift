import Foundation
import StateTree

public struct AppNode: Node {

  public nonisolated init() { }

  @Value var authentication: Authentication?
  @Route public var gameOrSignIn: Union
    .Two<GameInfoNode, UnauthenticatedNode> = .b(.init(authentication: .constant(nil)))

  public var rules: some Rules {
    if let auth = $authentication.compact() {
      Serve(
        .a(GameInfoNode(authentication: auth) {
          authentication = nil
        }),
        at: $gameOrSignIn
      )
    } else {
      Serve(
        .b(UnauthenticatedNode(authentication: $authentication)),
        at: $gameOrSignIn
      )
    }
  }
}
