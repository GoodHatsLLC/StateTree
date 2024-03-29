import StateTree

// MARK: - UnauthenticatedNode

public struct UnauthenticatedNode: Node {

  // MARK: Lifecycle

  public init(authentication: Projection<Authentication?>) {
    _authentication = authentication
  }

  // MARK: Public

  @Value public private(set) var shouldHint = false
  @Value public private(set) var isLoading = false

  public var rules: some Rules { () }

  public func authenticate(
    playerX: String,
    playerO: String,
    password: String
  ) {
    isLoading = true

    $scope
      .action(.id("auth")) {
        try await authClient
          .auth(
            playerX: playerX,
            playerO: playerO,
            password: password
          )
      } onSuccess: { auth in
        shouldHint = false
        authentication = auth
        isLoading = false
      } onFailure: { _ in
        shouldHint = true
        isLoading = false
      }
  }

  // MARK: Private

  @Scope private var scope
  @Projection private var authentication: Authentication?

  @Dependency(\.authClient) private var authClient: any AuthClientType

}
