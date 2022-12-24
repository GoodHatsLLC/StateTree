import Foundation
import StateTree

public struct AppModel: Model {

  public init(
    store: Store<Self>
  ) {
    self.store = store
  }

  public struct State: ModelState {
    public init(authentication: Authentication? = nil) {
      self.authentication = authentication
    }

    var authentication: Authentication?
  }

  @Route<GameInfoModel> public var loggedIn

  @Route<UnauthenticatedModel> public var loggedOut

  public let store: Store<Self>

  @DidActivate<Self> var start = { _ in

    debugPrint("APP: start")
  }

  @RouteBuilder
  public func route(state: Projection<State>) -> some Routing {
    if let auth = state.authentication.compact() {
      $loggedIn.route(auth, into: .init(authentication: auth.value)) { from, to in
        from <-> to.authentication
      } model: { store in
        GameInfoModel(store: store, logout: logoutBehavior)
      }

    } else {
      let unAuthState = state.authentication

      $loggedOut
        .route(unAuthState, into: .init()) { from, to in
          from <-> to.authentication
        } model: { store in
          .init(store: store)
        }
        .dependency(\.authClient, AuthClientImpl())
    }
  }

  private var logoutBehavior: Behavior<Void> {
    Behavior {
      store.transaction { state in
        state.authentication = nil
      }
    }
  }
}
