import Disposable
import StateTree
import StateTreePlayback
import XCTest

// MARK: - PlaybackTests

final class PlaybackTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() {
    NodeID
      .incrementForTesting()
      .stage(on: stage)
  }

  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_startFrom() async throws {
    let tree = try Tree.main
      .start(
        root: RootNode()
      )
    tree.stage(on: stage)
    let recorder = tree.recorder()
    try recorder.start()
  }

}

extension PlaybackTests {

  // MARK: - Square

  struct SubSubNode: Node {
    @Projection var value: Int
    var rules: some Rules { .none }
  }

  struct SubNode: Node {

    @Route(SubSubNode.self) var subSubRoute
    @Value var subValue = 32
    @Projection var value: Int

    var rules: some Rules {
      if subValue == 2 {
        $subSubRoute.route {
          SubSubNode(value: $value)
        }
      }
    }
  }

  // MARK: - RootNode

  struct RootNode: Node {

    @Value var routeIfNegative = 0
    @Route(SubNode.self) var subRoute

    var rules: some Rules {
      if routeIfNegative < 0 {
        $subRoute.route {
          SubNode(value: $routeIfNegative)
        }
      }
    }
  }

  // MARK: - Square

  struct Square: Node {

    @Value var square: Int!
    @Projection var value: Int

    var rules: some Rules {
      OnChange(value) { value in
        square = value * value
      }
    }
  }

  // MARK: - PrimeSquare

  struct PrimeSquare: Node {

    @Value var potentialPrime = 0
    @Route(Square.self) var primeSquared

    var rules: some Rules {
      if isPrime(potentialPrime) {
        $primeSquared.route {
          Square(value: $potentialPrime)
        }
      }
    }

    private func isPrime(_ num: Int) -> Bool {
      guard num >= 2 else {
        return false
      }
      guard num != 2 else {
        return true
      }
      guard num % 2 != 0 else {
        return false
      }
      return !stride(
        from: 3,
        through: Int(sqrt(Double(num))),
        by: 2
      ).contains { num % $0 == 0 }
    }

  }

}
