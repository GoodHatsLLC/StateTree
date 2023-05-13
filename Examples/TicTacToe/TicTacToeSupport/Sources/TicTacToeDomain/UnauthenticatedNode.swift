import StateTree

// MARK: - UnauthenticatedNode

public struct UnauthenticatedNode: Node {

  // MARK: Lifecycle

  public init(authentication: Projection<Authentication?>) {
    _authentication = authentication
  }

  // MARK: Public

  @Value public var shouldHint = false
  @Value public var isLoading = false

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
      } success: { auth in
        shouldHint = false
        authentication = auth
        isLoading = false
      } failure: { _ in
        shouldHint = true
        isLoading = false
      }
  }

  // MARK: Internal

  @Scope var scope
  @Projection var authentication: Authentication?

  // MARK: Private

  @Dependency(\.authClient) private var authClient: any AuthClientType

}
