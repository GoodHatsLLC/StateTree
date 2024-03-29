import Disposable
import Emitter
import TreeActor
import Utilities
import XCTest
@_spi(Implementation) @testable import Behavior

// MARK: - SyncSingleTests

final class SyncSingleTests: XCTestCase {

  let stage = DisposableStage()
  var tracker: BehaviorTracker!

  override func setUp() {
    tracker = BehaviorTracker()
  }

  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_sync_onSuccess() async throws {
    let didSucceed = Async.Value<Bool>()
    let behavior: Behaviors.SyncSingle<Void, Int, Never> = Behaviors
      .make(.id("test_sync_success"), input: Void.self) { () -> Int in
        123_321
      }
    let res = behavior
      .run(tracker: tracker, scope: stage, input: (), handler: .init(onSuccess: { value in
        XCTAssertEqual(value, 123_321)
        Task { await didSucceed.resolve(to: true) }
      }, onCancel: {
        XCTFail()
      }))

    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_sync_success"))
    XCTAssertEqual(resolved.state, .finished)
    let success = await didSucceed.value
    XCTAssert(success)
  }

  @TreeActor
  func test_spi_immediate_cancel_result() async throws {
    stage.dispose()
    let behavior: Behaviors.SyncSingle<Void, Int, Never> = Behaviors
      .make(.auto(), input: Void.self) { () -> Int in
        XCTFail()
        return 1
      }
    let scoped = behavior
      .run(tracker: tracker, scope: stage, input: ())
    let value = await scoped.value
    XCTAssertEqual(value.state, .cancelled)
  }

  @TreeActor
  func test_throwing_sync_success() async throws {
    let shouldError = false
    var didSucceed = false
    let behavior: Behaviors.SyncSingle<Void, Int, Error> = Behaviors
      .make(.id("test_throwing_sync_success"), input: Void.self) { () throws -> Int in
        if shouldError {
          XCTFail("test setup issue")
          throw TestError()
        } else {
          return 234_124
        }
      }
    let res = behavior
      .run(tracker: tracker, scope: stage, input: (), handler: .init(onResult: { result in
        guard case .success(let value) = result
        else {
          XCTFail()
          return
        }
        XCTAssertEqual(234_124, value)
        didSucceed = true
      }, onCancel: {
        XCTFail()
      }))

    XCTAssert(didSucceed, "didSucceed should be synchronously set")
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_throwing_sync_success"))
    XCTAssertEqual(resolved.state, .finished)
    try await tracker.awaitReady()
    try await tracker.awaitBehaviors()
  }

  @TreeActor
  func test_throwing_sync_failure() async throws {
    let shouldError = true
    var didFail = false
    let behavior: Behaviors.SyncSingle<Void, Int, Error> = Behaviors
      .make(.id("test_throwing_sync_failure"), input: Void.self) { () throws -> Int in
        if shouldError {
          throw TestError()
        } else {
          XCTFail("test setup issue")
          return 234_124
        }
      }
    let res = behavior
      .run(tracker: tracker, scope: stage, input: (), handler: .init(onResult: { result in
        guard
          case .failure(let error) = result,
          error is TestError
        else {
          XCTFail()
          return
        }
        didFail = true
      }, onCancel: {
        XCTFail()
      }))

    XCTAssert(didFail, "didFail should be synchronously set")
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_throwing_sync_failure"))
    XCTAssertEqual(resolved.state, .failed)
    try await tracker.awaitReady()
    try await tracker.awaitBehaviors()
  }

  @TreeActor
  func test_interception() async throws {
    let initial = 123_321
    let replacement = 100_000
    var received: Int?
    tracker = .init(behaviorInterceptors: [
      BehaviorInterceptor(
        id: .id("test_interception"),
        type: Behaviors.SyncSingle<Void, Int, Never>.self,
        subscriber: .init { _ in .always {
          replacement
        }}
      ),
    ])
    let behavior: Behaviors.SyncSingle<Void, Int, Never> = Behaviors
      .make(.id("test_interception"), input: Void.self) { () -> Int in
        initial
      }
    _ = behavior
      .run(tracker: tracker, scope: stage, input: (), handler: .init(onSuccess: { value in
        received = value
      }, onCancel: {
        XCTFail()
      }))

    XCTAssertEqual(received, replacement)
    try await tracker.awaitReady()
    try await tracker.awaitBehaviors()
  }

  func test_inferredType_Throwing() async throws {
    let fun: () -> Bool = { true }
    let behavior = await Behaviors.make(input: Void.self) {
      if fun() {
        throw TestError()
      } else {
        return true
      }
    }
    XCTAssert(type(of: behavior) == Behaviors.SyncSingle<Void, Bool, Error>.self)
  }

  func test_inferredType_NonThrowing() async throws {
    let fun: () -> Bool = { true }
    let behavior = await Behaviors.make(input: Void.self) {
      fun()
    }
    XCTAssert(type(of: behavior) == Behaviors.SyncSingle<Void, Bool, Never>.self)
  }
}
