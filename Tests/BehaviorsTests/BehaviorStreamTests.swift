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
    let asyncBlock = Async.Value<Void>()
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
    let receivedError = Async.Value<Error>()
    let behavior = Behaviors
      .make(.id("stream_fail")) { () async -> AsyncThrowingStream<Int, any Error> in
        AsyncThrowingStream<Int, any Error> {
          throw TestError()
        }
      }.scoped(to: stage, manager: .init())
    let subnodeResolution = await behavior
      .onValue { _ in
        XCTFail()
      } onFinish: {
        XCTFail()
      } onFailure: { error in
        Task { await receivedError.resolve(error) }
      } onCancel: {
        XCTFail()
      }
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("stream_fail"))
    XCTAssertEqual(resolved.state, .failed)
    let error = await receivedError.value
    XCTAssert(error is TestError)
  }

  func test_eventual_failure() async throws {
    let subject = PublishSubject<Int>()
    var receivedError: Error?
    var receivedOutput: [Int] = []
    let asyncBlocks: [Async.Value<Void>] = [.init(), .init()]
    let manager = BehaviorManager()
    let subnodeResolution = await Behaviors.make(.id("stream_eventual_fail")) {
      subject.values
    }
    .scoped(to: stage, manager: manager)
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
    await manager.awaitReady()
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

#if canImport(Combine)
import Combine
extension BehaviorStreamTests {

  func test_combine_publisher() async throws {
    let publisher = [1, 2, 3, 4].publisher
    var receivedOutput: [Int] = []
    var didFinish = false
    let manager = BehaviorManager()
    let behavior = await Behaviors.make(.id("combine_stream")) {
      publisher.values
    }
    .scoped(to: stage, manager: manager)
    .onValue { value in
      receivedOutput.append(value)
    } onFinish: {
      didFinish = true
    } onFailure: { _ in
      XCTFail()
    } onCancel: {
      XCTFail()
    }
    let resolved = await behavior.value
    XCTAssert(didFinish)
    XCTAssertEqual(resolved.id, .id("combine_stream"))
    XCTAssertEqual(resolved.state, .finished)
    XCTAssertEqual(receivedOutput, [1, 2, 3, 4])
  }

  func test_combine_subject() async throws {
    let subject = PassthroughSubject<Int, Never>()
    var receivedOutput: [Int] = []
    var didFinish = false
    let manager = BehaviorManager()
    let value = Async.Value<Cancellable>()
    let behavior = await Behaviors.make(.id("combine_stream")) {
      let asyncSubject = Async.Subject<Int>()
      let sub = subject
        .sink { _ in
          asyncSubject.finish()
        } receiveValue: { value in
          asyncSubject.send(value)
        }
      await value.resolve(sub)
      return asyncSubject
    }
    .scoped(to: stage, manager: manager)
    .onValue { value in
      receivedOutput.append(value)
    } onFinish: {
      didFinish = true
    } onFailure: { _ in
      XCTFail()
    } onCancel: {
      XCTFail()
    }
    await manager.awaitReady()
    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(completion: .finished)
    let resolved = await behavior.value
    XCTAssert(didFinish)
    XCTAssertEqual(resolved.id, .id("combine_stream"))
    XCTAssertEqual(resolved.state, .finished)
    XCTAssertEqual(receivedOutput, [1, 2, 3, 4])
  }
}
#endif
