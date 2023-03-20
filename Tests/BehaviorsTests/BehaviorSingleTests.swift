import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities
import XCTest

// MARK: - BehaviorSingleTests

final class BehaviorSingleTests: XCTestCase {

  let stage = DisposableStage()
  var manager: BehaviorManager!

  override func setUp() {
    manager = BehaviorManager(trackingConfig: .track)
  }

  override func tearDown() {
    stage.reset()
  }

  func test_onSuccess() async throws {
    let didSucceed = Async.Value<Bool>()
    let behavior = Behaviors.make(.id("test_success")) { () async -> Int in
      123_321
    }
    .scoped(to: stage, manager: manager)

    let res = await behavior
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

  func test_immediate_cancel_result() async throws {
    stage.dispose()
    let cancellationResult = await Behaviors.make(.auto()) { () async -> Int in
      123
    }
    .scoped(to: stage, manager: manager)
    .result
    XCTAssertEqual(
      cancellationResult,
      .failure(Behaviors.cancellation)
    )
  }

  func test_get_success() async throws {
    let value = try await Behaviors.make(.auto()) { () async -> Int in
      123_555
    }
    .scoped(to: stage, manager: manager)
    .get()
    XCTAssertEqual(
      value, 123_555,
      "the success value should be passed through to get()"
    )
  }

  func test_get_immediate_throwingCancel() async throws {
    stage.dispose()
    var didThrow = false
    do {
      _ = try await Behaviors.make(.auto()) { () async -> Int in
        123
      }
      .scoped(to: stage, manager: manager)
      .get()
      XCTFail()
    } catch {
      didThrow = true
    }
    _ = await manager.behaviorResolutions
    XCTAssert(didThrow)
  }

  func test_get_eventual_throwingCancel() async throws {
    let value = Async.Value<Int>()
    let didThrow = Async.Value<Bool>()
    let behavior = Behaviors.make(.auto()) { () async -> Int in
      await value.value
    }
    .scoped(to: stage, manager: manager)

    Task {
      do {
        _ = try await behavior.get()
        XCTFail()
      } catch {
        await didThrow.resolve(true)
      }
    }
    Task {
      stage.dispose()
    }
    _ = await manager.behaviorResolutions
    let didThrowValue = await didThrow.value
    XCTAssert(didThrowValue)
  }

  func test_sync_onSuccess() async throws {
    let didSucceed = Async.Value<Bool>()
    let behavior = Behaviors.make(.id("test_sync_success")) { () -> Int in
      123_321
    }
    .scoped(to: stage, manager: manager)

    let res = await behavior
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

  func test_sync_immediate_cancel_result() async throws {
    stage.dispose()
    let cancellationResult = await Behaviors.make(.auto()) { () -> Int in
      123
    }
    .scoped(to: stage, manager: manager)
    .result
    XCTAssertEqual(
      cancellationResult,
      .failure(Behaviors.cancellation)
    )
  }

  func test_sync_get_success() async throws {
    let value = try await Behaviors.make(.auto()) { () -> Int in
      123_555
    }
    .scoped(to: stage, manager: manager)
    .get()
    XCTAssertEqual(
      value, 123_555,
      "the success value should be passed through to get()"
    )
  }

  func test_sync_get_immediate_throwingCancel() async throws {
    stage.dispose()
    var didThrow = false
    do {
      _ = try await Behaviors.make(.auto()) { () -> Int in
        123
      }
      .scoped(to: stage, manager: manager)
      .get()
      XCTFail()
    } catch {
      didThrow = true
    }
    _ = await manager.behaviorResolutions
    XCTAssert(didThrow)
  }

  func test_sync_get_eventual_throwingCancel() async throws {
    let value = Async.Value<Int>()
    let didThrow = Async.Value<Bool>()
    let behavior = Behaviors.make(.auto()) { () -> Int in
      await value.value
    }
    .scoped(to: stage, manager: manager)
    await manager.awaitReady()
    Task {
      do {
        _ = try await behavior.get()
        XCTFail()
      } catch {
        await didThrow.resolve(true)
      }
    }
    Task {
      stage.dispose()
    }
    _ = await manager.behaviorResolutions
    let didThrowValue = await didThrow.value
    XCTAssert(didThrowValue)
  }

  func test_throwing_success() async throws {
    let shouldError = false
    let didSucceed = Async.Value<Bool>()
    let res = await Behaviors.make(.id("test_throwing_success")) { () async throws -> Int in
      if shouldError {
        XCTFail("test setup issue")
        throw TestError()
      } else {
        234_124
      }
    }
    .scoped(to: stage, manager: .init())
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
    let res = await Behaviors.make(.id("test_throwing_failure")) { () async throws -> Int in
      if shouldError {
        throw TestError()
      } else {
        XCTFail("test setup issue")
        return 234_124
      }
    }
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
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_throwing_failure"))
    XCTAssertEqual(resolved.state, .failed)
    XCTAssert(didFail)
  }

  func test_throwing_sync_success() async throws {
    let shouldError = false
    let didSucceed = Async.Value<Bool>()
    let res = await Behaviors.make(.id("test_throwing_sync_success")) { () throws -> Int in
      if shouldError {
        XCTFail("test setup issue")
        throw TestError()
      } else {
        234_124
      }
    }
    .scoped(to: stage, manager: .init())
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
    XCTAssertEqual(resolved.id, .id("test_throwing_sync_success"))
    XCTAssertEqual(resolved.state, .finished)
    let success = await didSucceed.value
    XCTAssert(success)
  }

  func test_throwing_sync_failure() async throws {
    let shouldError = true
    var didFail = false
    let res = await Behaviors.make(.id("test_throwing_sync_failure")) { () throws -> Int in
      if shouldError {
        throw TestError()
      } else {
        XCTFail("test setup issue")
        return 234_124
      }
    }
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
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_throwing_sync_failure"))
    XCTAssertEqual(resolved.state, .failed)
    XCTAssert(didFail)
  }
}
