import Foundation
import StateTree

public struct AppModel: Node {

  public nonisolated init() { }

  @Value private var authentication: Authentication?
  @Route(GameInfoModel.self, UnauthenticatedModel.self) public var gameOrSignIn

  public var rules: some Rules {
    if let auth = $authentication.compact() {
      $gameOrSignIn.route {
        .a(
          GameInfoModel(authentication: auth) {
            authentication = nil
          }
        )
      }
    } else {
      $gameOrSignIn.route {
        .b(
          UnauthenticatedModel(
            authentication: $authentication
          )
        )
      }
    }
  }
}
