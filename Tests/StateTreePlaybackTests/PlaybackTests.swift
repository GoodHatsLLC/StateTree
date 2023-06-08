import Behavior
import Disposable
import StateTree
import StateTreePlayback
import TreeActor
import Utilities
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
    try tree.start()
    let recorder = Recorder(tree: tree)
    try recorder
      .start()
      .autostop()
      .stage(on: stage)

    let root = try tree.assume.rootNode
    root.setNumber(to: 3)
    await tree.once.behaviorsFinished()
    root.setNumber(to: 0)
    await tree.once.behaviorsFinished()
    try tree.stop()
    _ = await tree.once.result()
    let frames = recorder.frames

    stage.reset()

    var created = [BehaviorID: Int]()
    var started = [BehaviorID: Int]()
    var finished = [BehaviorID: Int]()

    frames.forEach { frame in
      switch frame.event.maybeBehavior {
      case .created(let id):
        created[id, default: 0] += 1
      case .started(let id):
        started[id, default: 0] += 1
      case .finished(let id):
        finished[id, default: 0] += 1
      default:
        break
      }
    }

    let all = [
      BehaviorID.id("onchange"): 1,
      .id("onstart"): 1,
      .id("onstop"): 1,
      .id("run"): 2,
    ]

    // Created events aren't super useful for visualization
    // and so are suppressed in playback.
    XCTAssertEqual(created, [:])
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
      OnUpdate(number, .id("onchange")) { _ in
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
    @Route var info: Union.Two<Prime, Composite>? = nil
    @Scope var scope

    var rules: some Rules {
      if isPrime(number) {
        Serve(.a(Prime(number: $number)), at: $info)
      } else {
        Serve(.b(Composite(number: $number)), at: $info)
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
