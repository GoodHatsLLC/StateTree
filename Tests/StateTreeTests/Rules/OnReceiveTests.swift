import Disposable
import Emitter
import Utilities
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
  func test_onReceive_finish_asyncSequence() async throws {
    let tree = try Tree.main
      .start(
        root: OnReceiveAsyncSequenceHost<AnyAsyncSequence<Int>>(sequence: AnyAsyncSequence<Int>([
          1,
          2,
          3,
          4,
          5,
          6,
          7,
        ]))
      )
    tree.stage(on: stage)
    let node = tree.root.node
    try await tree.awaitBehaviors()
    XCTAssertEqual(node.vals.sorted(), [0, 1, 2, 3, 4, 5, 6, 7])
  }

  @TreeActor
  func test_onReceive_finish() async throws {
    let subject = PublishSubject<Int>()
    let tree = try Tree.main
      .start(root: OnReceiveHost(emitter: subject.erase()))
    tree.stage(on: stage)
    let node = tree.root.node
    try await tree.awaitReady()
    XCTAssertEqual(node.vals, [])
    subject.emit(value: 1)
    subject.emit(value: 2)
    subject.emit(value: 3)
    subject.finish()
    await Flush.tasks()
    subject.fail(TestError())
    try await tree.awaitBehaviors()
    XCTAssertEqual(node.vals.sorted(), [0, 1, 2, 3])
  }

  @TreeActor
  func test_onReceive_fail() async throws {
    let subject = PublishSubject<Int>()
    let tree = try Tree.main
      .start(root: OnReceiveHost(emitter: subject.erase()))
    tree.stage(on: stage)
    let node = tree.root.node
    try await tree.awaitReady()
    XCTAssertEqual(node.vals, [])
    subject.emit(value: 11)
    subject.emit(value: 22)
    subject.emit(value: 33)
    subject.fail(TestError())
    await Flush.tasks()
    subject.finish()
    try await tree.awaitBehaviors()
    XCTAssertEqual(node.vals.sorted(), [-1, 11, 22, 33])
  }

  @TreeActor
  func test_onReceive_cancel() async throws {
    let subject = PublishSubject<Int>()
    let tree = try Tree.main
      .start(root: OnReceiveHost(emitter: subject.erase()))
    tree.stage(on: stage)
    let node = tree.root.node
    try await tree.awaitReady()
    XCTAssertEqual(node.vals, [])
    subject.emit(value: 11)
    subject.emit(value: 22)
    await Flush.tasks()
    stage.dispose()
    subject.emit(value: 33)
    subject.fail(TestError())
    subject.finish()
    try await tree.awaitBehaviors()
    XCTAssertEqual(node.vals.sorted(), [11, 22])
  }
}

#if canImport(Combine)
extension OnReceiveTests {
  @TreeActor
  func test_onReceive_publisher() async throws {
    let subject = PassthroughSubject<Int, Never>()
    let tree = try Tree.main
      .start(root: OnReceiveCombineHost(publisher: subject))
    tree.stage(on: stage)
    let node = tree.root.node
    try await tree.awaitReady()
    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(5)
    subject.send(6)
    subject.send(7)
    subject.send(completion: .finished)
    subject.send(8)
    subject.send(9)
    try await tree.awaitBehaviors()
    XCTAssertEqual(node.vals.sorted(), [0, 1, 2, 3, 4, 5, 6, 7])
  }
}
#endif

extension OnReceiveTests {

  struct OnReceiveHost: Node {

    let emitter: AnyEmitter<Int>
    @Value var vals: [Int] = []

    var rules: some Rules {
      OnReceive(emitter) { value in
        vals.append(value)
      } onFinish: {
        vals.append(0)
      } onFailure: { _ in
        vals.append(-1)
      }
    }
  }

  struct OnReceiveAsyncSequenceHost<Seq: AsyncSequence>: Node where Seq.Element == Int {

    let sequence: Seq
    @Value var vals: [Int] = []

    var rules: some Rules {
      OnReceive(sequence) { value in
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

#if canImport(Combine)
import Combine
extension OnReceiveTests {

  struct OnReceiveCombineHost<P: Publisher>: Node where P.Output == Int {

    let publisher: P
    @Value var vals: [Int] = []

    var rules: some Rules {
      OnReceive(publisher) { value in
        vals.append(value)
      } onFinish: {
        vals.append(0)
      } onFailure: { _ in
        vals.append(-1)
      }
    }
  }

}

#endif
