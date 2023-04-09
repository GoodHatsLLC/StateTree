import Behavior
import Disposable
import StateTree
import StateTreePlayback
import XCTest

// MARK: - PlaybackTests

final class PlaybackTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_behaviorEventEmissions_areBalanced() async throws {
    let tree = Tree(
      root: PrimeTest()
    )
    await tree.run(on: stage)
    let recorder = tree.recorder()
    let handle = try recorder
      .start()
    let root = try tree.rootNode
    root.setNumber(to: 3)
    try await tree.awaitBehaviors()
    root.setNumber(to: 0)
    try await tree.awaitBehaviors()
    stage.reset()
    let frames = recorder.frames
    handle.dispose()

    var created = [BehaviorID: Int]()
    var started = [BehaviorID: Int]()
    var finished = [BehaviorID: Int]()

    frames.forEach { frame in
      switch frame.event {
      case .behaviorCreated(let id):
        created[id, default: 0] += 1
      case .behaviorStarted(let id):
        started[id, default: 0] += 1
      case .behaviorFinished(let id):
        finished[id, default: 0] += 1
      default:
        break
      }
    }

    let all: [BehaviorID: Int] = [
      .id("onchange"): 1,
      .id("onstart"): 1,
      .id("onstop"): 1,
      .id("run"): 2,
    ]
    XCTAssertEqual(created, all)
    XCTAssertEqual(started, all)
    XCTAssertEqual(finished, all)
  }

}

extension PlaybackTests {

  // MARK: - RootNode

  struct Composite: Node {

    @Projection var number: Int

    var rules: some Rules { () }
  }

  // MARK: - Square

  struct Prime: Node {

    @Projection var number: Int

    var rules: some Rules {
      OnChange(number, .id("onchange")) { _ in
        noop()
      }
      OnStart(.id("onstart")) {
        noop()
      }
      OnStop(.id("onstop")) {
        noop()
      }
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
      $scope.run(.id("run")) {
        self.number = number
      }
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

  static func noop() { }

}
