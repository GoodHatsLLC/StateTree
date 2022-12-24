import StateTree

// MARK: - UnauthenticatedModel

public struct UnauthenticatedModel: Model {

  public init(
    store: Store<UnauthenticatedModel>
  ) {
    self.store = store
  }

  public struct State: ModelState {
    public init(
      authentication: Authentication? = nil,
      shouldHint: Bool = false
    ) {
      self.authentication = authentication
      self.shouldHint = shouldHint
    }

    var authentication: Authentication?
    public var shouldHint = false
  }

  public let store: Store<Self>

  @DidActivate<Self> var start = { _ in

    debugPrint("UNAUTHENTICATED: start")
  }

  @RouteBuilder
  public func route(state _: Projection<State>) -> some Routing {
    VoidRoute()
  }

  public func authenticate(username: String, password: String) {
    Behavior("login") {
      let auth = try? await authClient.auth(name: username, password: password)
      store.transaction { state in
        if let auth {
          state.authentication = auth
          state.shouldHint = false
        } else {
          state.shouldHint = true
        }
      }
    }.run(with: self)
  }

  @Dependency(\.authClient) private var authClient: any AuthClient

}
