import StateTree

// MARK: - UnauthenticatedModel

public struct UnauthenticatedModel: Node {

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
      .run {
        try await authClient
          .auth(
            playerX: playerX,
            playerO: playerO,
            password: password
          )
      }
      .onResult { result in
        $scope.transaction {
          do {
            let auth = try result.get()
            shouldHint = false
            authentication = auth
            isLoading = false
          } catch {
            shouldHint = true
            isLoading = false
          }
        }
      } onCancel: {
        isLoading = false
      }
  }

  // MARK: Internal

  @Scope var scope
  @Projection var authentication: Authentication?

  // MARK: Private

  @Dependency(\.authClient) private var authClient: AuthClient

}
