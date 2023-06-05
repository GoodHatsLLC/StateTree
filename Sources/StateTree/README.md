#  StateTree

The `StateTree` module re-exports `StateTreeBase` with API additions necessary
only within an app's domain logic (non-presentation / non-ui) layer.

```swift

struct UserEditNode: Node {

  // `projectedValue` access to @Projection is provided by this module.
  // (i.e. $userID: Projection<UserDataModel>)
  @Projection var userID: UserDataModel

  // `projectedValue` access to @Value is provided by this module.
  // (i.e. $promptDelete: Projection<Bool>)
  @Value private var promptDelete: Bool = false

  // `projectedValue` access to @Route is provided by this module.
  // (i.e. $deleteVerification: Route<MaybeSingleRouter<DeleteVerificationNode>>)
  @Route var deleteVerification: DeleteVerificationNode? = nil

  var rules: some Rules {
    if promptDelete {
      Serve(
        DeleteVerificationNode(
          isPrompting: $promptDelete, // N.B.: @Value's use.
          for: $userID                // N.B.: @Projection's use.
        ),
        at: $deleteVerification       // N.B.: @Route's use.
      )
    }
  }

}

```
