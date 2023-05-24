import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - StartStopTests

final class StartStopTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_startStop() async throws {
    var startCount = 0
    var stopCount = 0
    let tree = Tree(
      root: StartStop(
        start: {
          startCount += 1
        },
        stop: {
          stopCount += 1
        }
      )
    )
    try tree.start()

    XCTAssertEqual(startCount, 1)
    XCTAssertEqual(stopCount, 0)
    try tree.stop()
    XCTAssertEqual(startCount, 1)
    XCTAssertEqual(stopCount, 1)
  }

  @TreeActor
  func test_subnode_startStop() async throws {
    var startCount = 0
    var stopCount = 0
    let tree = Tree(
      root: StartStopHost(
        start: {
          startCount += 1
        },
        stop: {
          stopCount += 1
        }
      )
    )
    try tree.start()

    XCTAssertEqual(startCount, 1)
    XCTAssertEqual(stopCount, 0)
    try tree.stop()
    XCTAssertEqual(startCount, 1)
    XCTAssertEqual(stopCount, 1)
  }
}

extension StartStopTests {

  // MARK: - StartStopHost

  struct StartStopHost: Node {
    let start: () -> Void
    let stop: () -> Void

    @Route var startStop: StartStop? = nil
    var rules: some Rules {
      Attach($startStop, to: StartStop(start: start, stop: stop))
    }
  }

  // MARK: - StartStop

  struct StartStop: Node {

    let start: () -> Void
    let stop: () -> Void
    var rules: some Rules {
      OnStop {
        stop()
      }
      OnStart {
        start()
      }
    }
  }

}
