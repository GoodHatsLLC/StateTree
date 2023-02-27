import Disposable
import XCTest
@_spi(Implementation) import StateTree

// MARK: - CycleHandlingTests

final class CycleHandlingTests: XCTestCase {

  let stage = DisposableStage()

  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_cycle() async throws {
    var cycleCount = 0
    let life = try Tree.main.start(
      root: Parent(),
      configuration: .init(userError: .custom { error in
        if error is CycleError {
          cycleCount += 1
        }
      })
    )
    life.stage(on: stage)
    XCTAssertEqual(0, cycleCount)
    XCTAssertEqual(0, life.rootNode.v1)

    // 1 should not trigger a cycle
    life.rootNode.v1 = 1
    XCTAssertEqual(0, cycleCount)
    XCTAssertEqual(1, life.rootNode.v1)

    // 2 should trigger a cycle and be rolled back
    life.rootNode.v1 = 2
    XCTAssertEqual(1, cycleCount)
    XCTAssertEqual(1, life.rootNode.v1)

    // resetting to 0 should continue to work as normal.
    life.rootNode.v1 = 0
    XCTAssertEqual(1, cycleCount)
    XCTAssertEqual(0, life.rootNode.v1)

    // resetting to 1 should continue to work as normal.
    life.rootNode.v1 = 1
    XCTAssertEqual(1, cycleCount)
    XCTAssertEqual(1, life.rootNode.v1)
  }
}

extension CycleHandlingTests {

  struct Child: Node {
    @Projection var v1: Int
    var rules: some Rules {
      OnChange(v1) { value in
        v1 = -value
      }
    }
  }

  struct Intermediate: Node {
    @Projection var v1: Int
    @Route(Child.self) var child

    var rules: some Rules {
      $child.route(to: Child(v1: $v1))
    }
  }

  struct Parent: Node {
    @Value var v1: Int = 0
    @Route(Intermediate.self) var child

    var rules: some Rules {
      OnChange(v1) { value in
        if value < 0 {
          v1 = 2
        }
      }
      if v1 > 1 {
        $child.route {
          Intermediate(v1: $v1)
        }
      }
    }
  }

}
