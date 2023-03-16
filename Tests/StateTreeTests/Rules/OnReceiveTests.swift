import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - OnReceiveTests

final class OnReceiveTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_onReceive_finish() async throws {
    let subject = PublishSubject<Int>()
    let tree = try Tree.main
      .start(root: OnReceiveHost(emitter: subject.erase()))
    tree.stage(on: stage)
    let node = tree.root.node
    XCTAssertEqual(node.val, nil)
    subject.emit(.value(1))
    XCTAssertEqual(node.val, 1)
    subject.emit(.value(2))
    XCTAssertEqual(node.val, 2)
    subject.emit(.finished)
    XCTAssertEqual(node.val, nil)
    subject.emit(.failed(TestError()))
    XCTAssertEqual(node.val, nil)
  }

  @TreeActor
  func test_onReceive_fail() async throws {
    let subject = PublishSubject<Int>()
    let tree = try Tree.main
      .start(root: OnReceiveHost(emitter: subject.erase()))
    tree.stage(on: stage)
    let node = tree.root.node
    XCTAssertEqual(node.val, nil)
    subject.emit(.value(1))
    XCTAssertEqual(node.val, 1)
    subject.emit(.failed(TestError()))
    XCTAssertEqual(node.val, -1)
    subject.emit(.finished)
    XCTAssertEqual(node.val, -1)
  }
}

extension OnReceiveTests {

  struct OnReceiveHost: Node {

    let emitter: AnyEmitter<Int>
    @Value var val: Int?

    var rules: some Rules {
      OnReceive(emitter) { value in
        val = value
      } onFinished: {
        val = nil
      } onError: { _ in
        val = -1
      }
    }
  }

  struct TestError: Error { }

}
