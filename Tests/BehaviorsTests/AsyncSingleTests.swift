import Disposable
import Emitter
import TreeActor
import Utilities
import XCTest
@testable import Behaviors

// MARK: - AsyncSingleTests

final class AsyncSingleTests: XCTestCase {

  let stage = DisposableStage()
  var tracker: BehaviorTracker!

  override func setUp() {
    tracker = BehaviorTracker()
  }

  override func tearDown() {
    stage.reset()
  }

  func test_onSuccess() async throws {
    let didSucceed = Async.Value<Bool>()
    let behavior: Behaviors.AsyncSingle<Void, Int, Never> = Behaviors
      .make(.id("test_success"), input: Void.self) { () async -> Int in
        123_321
      }
    let scoped = behavior
      .scoped(to: stage, tracker: tracker)

    let res = scoped
      .onSuccess { value in
        XCTAssertEqual(value, 123_321)
        Task { await didSucceed.resolve(true) }
      } onCancel: {
        XCTFail()
      }

    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_success"))
    XCTAssertEqual(resolved.state, .finished)
    let success = await didSucceed.value
    XCTAssert(success)
  }

  func test_immediate_cancel() async throws {
    stage.dispose()
    var didCancel = false
    let behavior: Behaviors.AsyncSingle<Void, Int, Error> = Behaviors
      .make(.auto(), input: Void.self) { () async -> Int in
        123
      }
    behavior
      .scoped(to: stage, tracker: tracker)
      .onResult { _ in
        XCTFail()
      } onCancel: {
        didCancel = true
      }
    try await tracker.awaitReady()
    XCTAssert(didCancel)
  }

  func test_eventual_throwingCancel() async throws {
    let never = Async.Value<Int>()
    let didRunTask = Async.Value<Bool>()
    var didCancel = false
    let behavior: Behaviors.AsyncSingle<Void, Int, Never> = Behaviors
      .make(.auto(), input: Void.self) { () async -> Int in
        await never.value
      }
    let scoped = behavior.scoped(to: stage, tracker: tracker)
    Task {
      await Flush.tasks()
      stage.dispose()
      await didRunTask.resolve(true)
    }
    _ = scoped.onSuccess { _ in
      XCTFail()
    } onCancel: {
      didCancel = true
    }
    try await tracker.awaitFinished()
    XCTAssert(didCancel)
    let didRun = await didRunTask.value
    XCTAssert(didRun)
  }

  func test_throwing_success() async throws {
    let shouldError = false
    let didSucceed = Async.Value<Bool>()
    let behavior: Behaviors.AsyncSingle<Void, Int, Error> = Behaviors
      .make(.id("test_throwing_success"), input: Void.self) { () async throws -> Int in
        if shouldError {
          XCTFail("test setup issue")
          throw TestError()
        } else {
          return 234_124
        }
      }
    let scoped = behavior
      .scoped(to: stage, tracker: .init())
    let res = scoped
      .onResult { result in
        guard case .success(let value) = result
        else {
          XCTFail()
          return
        }
        XCTAssertEqual(234_124, value)
        Task { await didSucceed.resolve(true) }
      } onCancel: {
        XCTFail()
      }
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_throwing_success"))
    XCTAssertEqual(resolved.state, .finished)
    let success = await didSucceed.value
    XCTAssert(success)
  }

  func test_throwing_failure() async throws {
    let shouldError = true
    var didFail = false
    let behavior: Behaviors.AsyncSingle<Void, Int, Error> = Behaviors
      .make(.id("test_throwing_failure"), input: Void.self) { () async throws -> Int in
        if shouldError {
          throw TestError()
        } else {
          XCTFail("test setup issue")
          return 234_124
        }
      }
    let res = behavior
      .scoped(to: stage, tracker: .init())
      .onResult { result in
        guard
          case .failure(let error) = result,
          error is TestError
        else {
          XCTFail()
          return
        }
        didFail = true
      } onCancel: {
        XCTFail()
      }
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_throwing_failure"))
    XCTAssertEqual(resolved.state, .failed)
    XCTAssert(didFail)
  }

  func test_interception() async throws {
    let initial = 123_321
    let replacement = 100_000
    var received: Int?
    tracker = .init(behaviorInterceptors: [
      BehaviorInterceptor(
        id: .id("test_interception"),
        type: Behaviors.AsyncSingle<Void, Int, Error>.self,
        subscriber: .init { _ in replacement }
      ),
    ])
    let behavior: Behaviors.AsyncSingle<Void, Int, Error> = Behaviors
      .make(.id("test_interception"), input: Void.self) { () async throws -> Int in
        initial
      }
    _ = behavior
      .scoped(to: stage, tracker: tracker)
      .onResult {
        switch $0 {
        case .success(let value):
          received = value
        case .failure:
          XCTFail()
        }
      }
    try await tracker.awaitFinished()
    XCTAssertEqual(received, replacement)
  }

  func test_inferredType_Throwing() async throws {
    let fun: () async -> Bool = { true }
    let behavior = Behaviors.make(input: Void.self) {
      if await fun() {
        throw TestError()
      } else {
        return true
      }
    }
    XCTAssert(type(of: behavior) == Behaviors.AsyncSingle<Void, Bool, Error>.self)
  }

  func test_inferredType_NonThrowing() async throws {
    let fun: () async -> Bool = { true }
    let behavior = Behaviors.make(input: Void.self) {
      await fun()
    }
    XCTAssert(type(of: behavior) == Behaviors.AsyncSingle<Void, Bool, Never>.self)
  }

}
