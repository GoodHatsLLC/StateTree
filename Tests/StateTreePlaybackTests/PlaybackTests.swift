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
        root: PrimeTest()
      )
    tree.stage(on: stage)
    let recorder = tree.recorder()
    let handle = try recorder
      .start()
    let root = tree.rootNode
    root.setNumber(to: 3)
    try await tree.awaitFinished()
    handle.dispose()
    let frames = recorder.frames
    debugPrint(frames)
  }

}

extension PlaybackTests {

  // MARK: - RootNode

  struct Composite: Node {

    @Projection var number: Int

    var rules: some Rules {
      ()
    }
  }

  // MARK: - Square

  struct Prime: Node {

    @Projection var number: Int

    var rules: some Rules {
      ()
    }
  }

  // MARK: - PrimeSquare

  struct PrimeTest: Node {

    // MARK: Internal

    @Value var number = 0
    @Route(Prime.self, Composite.self) var info
    @Scope var scope

    var rules: some Rules {
      if isPrime(number) {
        try $info.route {
          Prime(number: $number)
        }
      } else {
        try $info.route {
          Composite(number: $number)
        }
      }
    }

    func setNumber(to number: Int) {
      $scope.run {
        self.number = number
      }.fireAndForget()
    }

    // MARK: Private

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
