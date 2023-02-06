import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - StageWhileActiveTests

@TreeActor
final class StageWhileActiveTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  func test_stageWhileActive() throws {
    var disposeCount = 0
    let tree = try Tree.main
      .start(
        root: DisposableHoster(disposable: AnyDisposable { disposeCount += 1 })
      )

    XCTAssertEqual(disposeCount, 0)
    tree.dispose()
    XCTAssertEqual(disposeCount, 1)
  }
}

// MARK: StageWhileActiveTests.DisposableHoster

extension StageWhileActiveTests {

  // MARK: - DisposableHoster

  struct DisposableHoster: Node {
    let disposable: AnyDisposable

    var rules: some Rules {
      Stage(disposable)
    }
  }

}
