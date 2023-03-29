import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities
import XCTest

// MARK: - SyncSingleTests

final class SyncSingleTests: XCTestCase {

  let stage = DisposableStage()
  var manager: BehaviorManager!

  override func setUp() {
    manager = BehaviorManager()
  }

  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_sync_onSuccess() async throws {
    let didSucceed = Async.Value<Bool>()
    let behavior: Behaviors.SyncSingle<Void, Int, Never> = Behaviors
      .make(.id("test_sync_success")) { () -> Int in
        123_321
      }
    let res = behavior
      .scoped(to: stage, manager: manager)
      .onSuccess { value in
        XCTAssertEqual(value, 123_321)
        Task { await didSucceed.resolve(true) }
      } onCancel: {
        XCTFail()
      }

    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_sync_success"))
    XCTAssertEqual(resolved.state, .finished)
    let success = await didSucceed.value
    XCTAssert(success)
  }

  @TreeActor
  func test_sync_immediate_cancel_result() async throws {
    stage.dispose()
    let behavior: Behaviors.SyncSingle<Void, Int, Never> = Behaviors.make(.auto()) { () -> Int in
      123
    }
    let scoped = behavior
      .scoped(to: stage, manager: manager)

    let result = scoped.result

    XCTAssertEqual(
      result,
      .failure(Behaviors.cancellation)
    )
  }

  @TreeActor
  func test_sync_get_success() async throws {
    let behavior: Behaviors.SyncSingle<Void, Int, Never> = Behaviors.make(.auto()) { () -> Int in
      123_555
    }
    let scoped = behavior
      .scoped(to: stage, manager: manager)

    let value = try scoped.result.get()
    XCTAssertEqual(
      value, 123_555,
      "the success value should be passed through to get()"
    )
    try await manager.awaitReady()
    try await manager.awaitFinished()
  }

  @TreeActor
  func test_sync_get_immediate_throwingCancel() async throws {
    stage.dispose()
    var didThrow = false
    do {
      let behavior: Behaviors.SyncSingle<Void, Int, Never> = Behaviors.make(.auto()) { () -> Int in
        123
      }
      let scoped = behavior
        .scoped(to: stage, manager: manager)

      _ = try scoped.result.get()
      XCTFail()
    } catch {
      didThrow = true
    }
    XCTAssert(didThrow)
    try await manager.awaitReady()
    try await manager.awaitFinished()
  }

  @TreeActor
  func test_throwing_sync_success() async throws {
    let shouldError = false
    var didSucceed = false
    let behavior: Behaviors.SyncSingle<Void, Int, Error> = Behaviors
      .make(.id("test_throwing_sync_success")) { () throws -> Int in
        if shouldError {
          XCTFail("test setup issue")
          throw TestError()
        } else {
          return 234_124
        }
      }
    let scoped = behavior
      .scoped(to: stage, manager: .init())

    let res = scoped
      .onResult { result in
        guard case .success(let value) = result
        else {
          XCTFail()
          return
        }
        XCTAssertEqual(234_124, value)
        didSucceed = true
      } onCancel: {
        XCTFail()
      }
    XCTAssert(didSucceed, "didSucceed should be synchronously set")
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_throwing_sync_success"))
    XCTAssertEqual(resolved.state, .finished)
    try await manager.awaitReady()
    try await manager.awaitFinished()
  }

  @TreeActor
  func test_throwing_sync_failure() async throws {
    let shouldError = true
    var didFail = false
    let behavior: Behaviors.SyncSingle<Void, Int, Error> = Behaviors
      .make(.id("test_throwing_sync_failure")) { () throws -> Int in
        if shouldError {
          throw TestError()
        } else {
          XCTFail("test setup issue")
          return 234_124
        }
      }
    let res = behavior
      .scoped(to: stage, manager: .init())
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
    XCTAssert(didFail, "didFail should be synchronously set")
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_throwing_sync_failure"))
    XCTAssertEqual(resolved.state, .failed)
    try await manager.awaitReady()
    try await manager.awaitFinished()
  }

  @TreeActor
  func test_interception() async throws {
    let initial = 123_321
    let replacement = 100_000
    var received: Int?
    manager = .init(behaviorInterceptors: [
      BehaviorInterceptor(
        id: .id("test_interception"),
        type: Behaviors.SyncSingle<Void, Int, Never>.self,
        subscriber: .init { _ in .always {
          replacement
        }}
      ),
    ])
    let behavior: Behaviors.SyncSingle<Void, Int, Never> = Behaviors
      .make(.id("test_interception")) { () -> Int in
        initial
      }
    _ = behavior
      .scoped(to: stage, manager: manager)
      .onSuccess { value in
        received = value
      } onCancel: {
        XCTFail()
      }
    XCTAssertEqual(received, replacement)
    try await manager.awaitReady()
    try await manager.awaitFinished()
  }

  func test_inferredType_Throwing() async throws {
    let fun: () -> Bool = { true }
    let behavior = await Behaviors.make {
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
    let behavior = await Behaviors.make {
      fun()
    }
    XCTAssert(type(of: behavior) == Behaviors.SyncSingle<Void, Bool, Never>.self)
  }
}