import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - StartStopTests

@TreeActor
final class StartStopTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  func test_startStop() throws {
    var startCount = 0
    var stopCount = 0
    let tree = try Tree.main
      .start(
        root: StartStop(
          start: {
            startCount += 1
          },
          stop: {
            stopCount += 1
          }
        )
      )

    XCTAssertEqual(startCount, 1)
    XCTAssertEqual(stopCount, 0)
    tree.dispose()
    XCTAssertEqual(startCount, 1)
    XCTAssertEqual(stopCount, 1)
  }

  func test_subnode_startStop() throws {
    var startCount = 0
    var stopCount = 0
    let tree = try Tree.main
      .start(
        root: StartStopHost(
          start: {
            startCount += 1
          },
          stop: {
            stopCount += 1
          }
        )
      )

    XCTAssertEqual(startCount, 1)
    XCTAssertEqual(stopCount, 0)
    tree.dispose()
    XCTAssertEqual(startCount, 1)
    XCTAssertEqual(stopCount, 1)
  }
}

extension StartStopTests {

  // MARK: - StartStopHost

  struct StartStopHost: Node {
    let start: () -> Void
    let stop: () -> Void

    @Route(StartStop.self) var startStop
    var rules: some Rules {
      $startStop.route {
        StartStop(start: start, stop: stop)
      }
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
