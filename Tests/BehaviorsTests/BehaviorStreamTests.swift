import Behaviors
import Disposable
import class Emitter.PublishSubject
import TreeActor
import Utilities
import XCTest

// MARK: - BehaviorStreamTests

final class BehaviorStreamTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  func test_success() async throws {
    let expected = [1, 2, 3, 4, 5, 6]
    var received: [Int] = []
    var didFinish = false
    let asyncBlock = AsyncValue<Void>()
    let behavior = Behaviors.make(.id("test_output_success")) {
      AnyAsyncSequence(expected)
    }.scoped(to: stage, manager: .init())
    let subnodeResolution = await behavior
      .onValue { value in
        received.append(value)
      } onFinish: {
        didFinish = true
        Task { await asyncBlock.resolve(()) }
      } onFailure: { _ in
        XCTFail()
      } onCancel: {
        XCTFail()
      }
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("test_output_success"))
    XCTAssertEqual(resolved.state, .finished)
    await asyncBlock.value
    XCTAssert(didFinish)
    XCTAssertEqual(received.sorted(), expected.sorted())
  }

  func test_immediate_failure() async throws {
    var receivedError: Error?
    let behavior = Behaviors.make(.id("stream_fail")) { () throws -> AnyAsyncSequence<Int> in
      throw TestError()
    }.scoped(to: stage, manager: .init())
    let subnodeResolution = await behavior
      .onValue { _ in
        XCTFail()
      } onFinish: {
        XCTFail()
      } onFailure: { error in
        receivedError = error
      } onCancel: {
        XCTFail()
      }
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("stream_fail"))
    XCTAssertEqual(resolved.state, .failed)
    XCTAssert(receivedError is TestError)
  }

  func test_eventual_failure() async throws {
    let subject = PublishSubject<Int>()
    var receivedError: Error?
    var receivedOutput: [Int] = []
    let asyncBlocks: [AsyncValue<Void>] = [.init(), .init()]
    let subnodeResolution = await Behaviors.make(.id("stream_eventual_fail")) {
      subject.values
    }
    .scoped(to: stage, manager: .init())
    .onValue { value in
      receivedOutput.append(value)
      if receivedOutput.count == 3 {
        Task { await asyncBlocks[0].resolve(()) }
      }
    } onFinish: {
      XCTFail()
    } onFailure: { error in
      receivedError = error
      Task { await asyncBlocks[1].resolve(()) }
    } onCancel: {
      XCTFail()
    }
    subject.emit(value: 3)
    subject.emit(value: 4)
    subject.emit(value: 5)
    await asyncBlocks[0].value
    subject.fail(TestError())
    await asyncBlocks[1].value
    subject.emit(value: 3)
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("stream_eventual_fail"))
    XCTAssertEqual(resolved.state, .failed)
    XCTAssert(receivedError is TestError)
    XCTAssertEqual(receivedOutput.sorted(), [3, 4, 5])
  }

}
