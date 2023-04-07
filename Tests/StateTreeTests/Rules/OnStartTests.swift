import Disposable
import Emitter
import Utilities
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - OnStartTests

final class OnStartTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_onStart_asyncSequence() async throws {
    let tree = Tree()
      .start(root: OnStartAsyncSequenceHost(sequence: AnyAsyncSequence<Int>([1, 2, 3, 4, 5, 6, 7])))
    tree.stage(on: stage)
    let node = tree.root.node
    try await tree.awaitBehaviors()
    XCTAssertEqual(node.vals.sorted(), [0, 1, 2, 3, 4, 5, 6, 7])
  }
}

extension OnStartTests {

  struct OnStartAsyncSequenceHost<Seq: AsyncSequence>: Node where Seq.Element == Int {

    let sequence: Seq
    @Value var vals: [Int] = []

    var rules: some Rules {
      OnStart {
        sequence
      } onValue: { value in
        vals.append(value)
      } onFinish: {
        vals.append(0)
      } onFailure: { _ in
        vals.append(-1)
      }
    }
  }

  struct TestError: Error { }

}
