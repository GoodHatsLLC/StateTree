import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities
import XCTest

// MARK: - BehaviorAsyncSingleTests

final class BehaviorAsyncSingleTests: XCTestCase {

  let stage = DisposableStage()
  var manager: BehaviorManager!

  override func setUp() {
    manager = BehaviorManager(trackingConfig: .track)
  }

  override func tearDown() {
    stage.reset()
  }

  func test_onSuccess() async throws {
    var didSucceed = false
    let behavior = Behaviors.make(.id("test_success")) { () async -> Int in
      123_321
    }
    .scoped(to: stage, manager: manager)

    let res = await behavior
      .onSuccess { value in
        XCTAssertEqual(value, 123_321)
        didSucceed = true
      } onCancel: {
        XCTFail()
      }

    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_success"))
    XCTAssertEqual(resolved.state, .finished)
    XCTAssert(didSucceed)
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
    let value = AsyncValue<Int>()
    let didThrow = AsyncValue<Bool>()
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
}
