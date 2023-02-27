# StateTree 🌳

StateTree brings reactive tools to the domain layer of an application.

* A 'state tree' is a domain model built by composing `Node` sub-models.
* A tree updates based on its state and its nodes' declaratively defined `Rules`.
* Tree state is fully serializable, and so StateTree supports time travel debugging.
* `StateTree` lets you model your domain's API *naturally*.
  1. It is explicitly not a `Redux` implementation.
  2. It makes reactivity easy. No reactive-streams/RxSwift/Combine required.
* The library's other primary concerns include:
  - Side effects and thier testability.
  - Deeplinkable state.
  - Dependency injection.
  - async/await support.
  - UI layer update minimization.

`StateTree` is implemented in Swift with familiar syntax heavily inspired by SwiftUI.
- `@State`, `@Binding`, and `@Environment` have direct equivalents.
- `var body: some View { ... }` is similarly analgous to `var rules: some Rules { ... }`.
- This package includes `StateTreeSwiftUI` for easy SwiftUI integration.

The library works on Linux — it has no proprietary dependencies.
Its state management model is similarly platform independent. `StateTree` could be reimplemented for any platform—and implementations could exchange serialized state.

StateTree is experimental at `v0.0.99` but its model and functionality has largely stabilized.
It will ship as `v0.1.0` with some more examples, documentation, and some rather exciting tooling.

## Importing with SPM

```swift
// Package dependencies
.package(url: "https://github.com/GoodHatsLLC/StateTree.git", .upToNextMajor(from: "0.0.99"))

// Domain layer product dependencies
.product(name: "StateTree", package: "StateTree"),

// UI layer product dependencies
.product(name: "StateTreeSwiftUI", package: "StateTree"),
```

## Examples

### TicTacToe

The examples in the `Workspace` folder and its are the best current resource. Read the [TicTacToe source](https://github.com/GoodHatsLLC/StateTree/tree/main/Workspace/Examples/TicTacToe) and run it from the [`xcworkspace`](https://github.com/GoodHatsLLC/StateTree/tree/main/Workspace/StateTree.xcworkspace).

![ttt](https://user-images.githubusercontent.com/509838/220849173-ecf1100a-dd9e-424d-bd38-0643fba5c2f1.gif)


### Domain modeling walkthrough

Let's model a domain that outputs the square of a number — but only
if it's prime.

Let's start with a sub-domain. We'll just write a `Node` that squares
its input — and ignore the prime bit for now.

```swift
struct Squarer: Node {

  // @Value fields are maintained by the
  // system — like SwiftUI's @State.

  @Value var output: Int! // Our output

  // @Projections are derived reference to @Values.
  // This relationship is like that between
  // SwiftUI's @Bindings and @State.

  @Projection var input: Int

  // Our `rules` define how the system updates
  // in response to state changes.
  // `var rules` is akin to a SwiftUI view's `body`.
  //
  // Rules declaratively define the system and are
  // reevaluated and reapplied when state changes.

  var rules: some Rules {
    OnChange(input) { input in
      output = input * input
    }
  }
}
```

Now let's grab some logic for calculating a prime from StackOverflow.

We can use this logic in another `Node`'s rules — and
'route' to our previous `Squarer` node only when an input
`Int` actually *is* a prime.

```swift
struct PrimeSquarer: Node {

  // The state in our system updates based on.
  // Like the output above `potentialPrime` is directly
  // owned by this Node, so is an @Value.

  @Value var potentialPrime: Int = 0

  // A sub-node that we 'route' to.
  // We're composing Nodes just like SwiftUI composes
  // views.
  // Sub-nodes need to be easy to access, so unlike
  // SwiftUI sub-views they're exposed as fields.

  @Route(Squarer.self) var primeSquared

  // We use our rules to define our systems behaviors
  // like when exactly routes should be populated.

  var rules: some Rules {
    if isPrime(potentialPrime) {
      $primeSquared.route(
        to: Squarer(value: $potentialPrime)
      )
    }
  }

  private func isPrime(_ num: Int) -> Bool {
    guard num >= 2     else { return false }
    guard num != 2     else { return true  }
    guard num % 2 != 0 else { return false }
    return !stride(
      from: 3,
      through: Int(sqrt(Double(num))),
      by: 2
    ).contains { num % $0 == 0 }
  }

}
```

When we run our `PrimeSquarer`, its logic and routing
happens in response to state changes — and automatically
updates the shape of our `Node` domain models.

```swift
import StateTree
import XCTest

final class Playground: XCTestCase {

  @TreeActor
  func test_primeSquareRouting() async throws {

    // Boot up the system.
    let tree = try Tree.main.start(
      root: PrimeSquare()
    )

    // Make changes and observe automatic updates

    tree.root.potentialPrime = 2
    XCTAssertEqual(tree.root.primeSquared?.square, 4)

    tree.root.potentialPrime = 4
    XCTAssertEqual(tree.root.primeSquared?.square, nil)

    tree.root.potentialPrime = 7
    XCTAssertEqual(tree.root.primeSquared?.square, 49)

    // Shut down the system and it cleans itself up.

    tree.dispose()

    XCTAssertEqual(tree.root.primeSquared?.square, nil)
  }
}
```
