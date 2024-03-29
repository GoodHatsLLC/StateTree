import Disposable
import class Emitter.PublishSubject
import TreeActor
import Utilities
import XCTest
@testable import Behavior

// MARK: - StreamTests

final class StreamTests: XCTestCase {

  let stage = DisposableStage()
  var tracker = BehaviorTracker()

  override func setUp() { }
  override func tearDown() {
    tracker = BehaviorTracker()
    stage.reset()
  }

  func test_success() async throws {
    let expected = [1, 2, 3, 4, 5, 6]
    var received: [Int] = []
    var didFinish = false
    let asyncBlock = Async.Value<Void>()
    let behavior: Behaviors.Stream<Void, Int, Error> = Behaviors
      .make(.id("test_output_success"), input: Void.self) {
        AnyAsyncSequence(expected)
      }
    let res = await behavior
      .run(tracker: tracker, scope: stage, input: (), handler: .init(onValue: { value in
        received.append(value)
      }, onFinish: {
        didFinish = true
        Task { await asyncBlock.resolve() }
      }, onFailure: { _ in
        XCTFail()
      }, onCancel: {
        XCTFail()
      }))
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_output_success"))
    XCTAssertEqual(resolved.state, .finished)
    await asyncBlock.value
    XCTAssert(didFinish)
    XCTAssertEqual(received.sorted(), expected.sorted())
  }

  func test_immediate_failure() async throws {
    let receivedError = Async.Value<Error>()
    let behavior: Behaviors.Stream<Void, Int, Error> = Behaviors
      .make(
        .id("stream_fail"),
        input: Void.self
      ) { () async -> AsyncThrowingStream<Int, any Error> in
        AsyncThrowingStream<Int, any Error> {
          throw TestError()
        }
      }

    let res = await behavior
      .run(tracker: tracker, scope: stage, input: (), handler: .init(onValue: { _ in
        XCTFail()
      }, onFinish: {
        XCTFail()
      }, onFailure: { error in
        Task { await receivedError.resolve(to: error) }
      }, onCancel: {
        XCTFail()
      }))

    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("stream_fail"))
    XCTAssertEqual(resolved.state, .failed)
    let error = await receivedError.value
    XCTAssert(error is TestError)
  }

  func test_eventual_failure() async throws {
    let subject = PublishSubject<Int, TestError>()
    var receivedError: Error?
    var receivedOutput: [Int] = []
    let asyncBlocks: [Async.Value<Void>] = [.init(), .init()]
    let tracker = BehaviorTracker()
    let behavior: Behaviors.Stream<Void, Int, Error> = Behaviors
      .make(.id("stream_eventual_fail"), input: Void.self) {
        subject.values
      }
    let res = await behavior
      .run(tracker: tracker, scope: stage, input: (), handler: .init(onValue: { value in
        receivedOutput.append(value)
        if receivedOutput.count == 3 {
          Task {
            await asyncBlocks[0].resolve()
          }
        }
      }, onFinish: {
        XCTFail()
      }, onFailure: { error in
        receivedError = error
        Task {
          await asyncBlocks[1].resolve()
        }
      }, onCancel: {
        XCTFail()
      }))
    try await tracker.awaitReady()
    subject.emit(value: 3)
    subject.emit(value: 4)
    subject.emit(value: 5)
    await asyncBlocks[0].value
    subject.fail(TestError())
    await asyncBlocks[1].value
    subject.emit(value: 3)
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("stream_eventual_fail"))
    XCTAssertEqual(resolved.state, .failed)
    XCTAssert(receivedError is TestError)
    XCTAssertEqual(receivedOutput.sorted(), [3, 4, 5])
  }

  func test_interception() async throws {
    let original = [1, 2, 3, 4, 5, 6]
    let expected = [0, 0, 0]
    var received: [Int] = []
    let tracker = BehaviorTracker(behaviorInterceptors: [
      .init(
        id: .id("test_interception"),
        type: Behaviors.Stream<Void, Int, Error>.self,
        subscriber: .init {
          AnyAsyncSequence(expected)
        },
        filter: { true }
      ),
    ])
    var didFinish = false
    let behavior: Behaviors.Stream<Void, Int, Error> = Behaviors
      .make(.id("test_interception"), input: Void.self) {
        AnyAsyncSequence(original)
      }
    let res = await behavior
      .run(tracker: tracker, scope: stage, input: (), handler: .init(onValue: { value in
        received.append(value)
      }, onFinish: {
        didFinish = true
      }, onFailure: { _ in
        XCTFail()
      }, onCancel: {
        XCTFail()
      }))
    _ = await res.value
    XCTAssertEqual(received, expected)
    XCTAssert(didFinish)
  }

  func test_inferredType_async() async throws {
    let fun: () async -> Bool = { true }
    let behavior = Behaviors.make(input: Void.self) {
      _ = await fun()
      return AnyAsyncSequence([true, false, true])
    }
    XCTAssert(type(of: behavior) == Behaviors.Stream<Void, Bool, Error>.self)
  }

}

#if canImport(Combine)
import Combine
extension StreamTests {

  func test_combine_publisher() async throws {
    let publisher = [1, 2, 3, 4].publisher
    var receivedOutput: [Int] = []
    var didFinish = false
    let tracker = BehaviorTracker()
    let res = await Behaviors.make(.id("combine_stream"), input: Void.self) {
      publisher.values
    }
    .run(tracker: tracker, scope: stage, input: (), handler: .init(onValue: { value in
      receivedOutput.append(value)
    }, onFinish: {
      didFinish = true
    }, onFailure: { _ in
      XCTFail()
    }, onCancel: {
      XCTFail()
    }))
    let resolved = await res.value
    XCTAssert(didFinish)
    XCTAssertEqual(resolved.id, .id("combine_stream"))
    XCTAssertEqual(resolved.state, .finished)
    XCTAssertEqual(receivedOutput, [1, 2, 3, 4])
  }

  func test_combine_subject() async throws {
    let subject = PassthroughSubject<Int, Never>()
    var receivedOutput: [Int] = []
    var didFinish = false
    let tracker = BehaviorTracker()
    let behavior = Behaviors.make(.id("combine_stream"), input: Void.self) {
      subject
    }
    let res = await behavior
      .run(tracker: tracker, scope: stage, input: (), handler: .init(onValue: { value in
        receivedOutput.append(value)
      }, onFinish: {
        didFinish = true
      }, onFailure: { _ in
        XCTFail()
      }, onCancel: {
        XCTFail()
      }))
    try await tracker.awaitReady()
    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(completion: .finished)
    let resolved = await res.value
    XCTAssert(didFinish)
    XCTAssertEqual(resolved.id, .id("combine_stream"))
    XCTAssertEqual(resolved.state, .finished)
    XCTAssertEqual(receivedOutput, [1, 2, 3, 4])
  }
}
#endif
