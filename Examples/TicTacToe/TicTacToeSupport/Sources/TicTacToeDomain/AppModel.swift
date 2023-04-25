import Foundation
import StateTree

public struct AppModel: Node {

  public nonisolated init() { }

  @Value var authentication: Authentication?
  @Route(GameInfoModel.self) public var loggedIn
  @Route(UnauthenticatedModel.self) public var loggedOut

  public var rules: some Rules {
    if let auth = $authentication.compact() {
      $loggedIn.route {
        GameInfoModel(authentication: auth) {
          authentication = nil
        }
      }
    } else {
      $loggedOut.route {
        UnauthenticatedModel(
          authentication: $authentication
        )
      }
    }
  }
}
