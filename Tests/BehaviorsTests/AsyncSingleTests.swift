import Behaviors
import Disposable
import Emitter
import TreeActor
import Utilities
import XCTest

// MARK: - AsyncSingleTests

final class AsyncSingleTests: XCTestCase {

  let stage = DisposableStage()
  var manager: BehaviorManager!

  override func setUp() {
    manager = BehaviorManager()
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
      .scoped(to: stage, manager: manager)

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

  func test_immediate_cancel_result() async throws {
    stage.dispose()
    let behavior: Behaviors.AsyncSingle<Void, Int, Never> = Behaviors
      .make(.auto(), input: Void.self) { () async -> Int in
        123
      }
    let scoped = behavior
      .scoped(to: stage, manager: manager)
    let cancellationResult = await scoped.result
    XCTAssertEqual(
      cancellationResult,
      .failure(Behaviors.cancellation)
    )
  }

  func test_get_success() async throws {
    let behavior: Behaviors.AsyncSingle<Void, Int, Never> = Behaviors
      .make(.auto(), input: Void.self) { () async -> Int in
        123_555
      }
    let scoped = behavior.scoped(to: stage, manager: manager)
    let value = try await scoped.result.get()
    XCTAssertEqual(
      value, 123_555,
      "the success value should be passed through to get()"
    )
  }

  func test_get_immediate_throwingCancel() async throws {
    stage.dispose()
    var didThrow = false
    do {
      let behavior: Behaviors.AsyncSingle<Void, Int, Error> = Behaviors
        .make(.auto(), input: Void.self) { () async -> Int in
          123
        }
      let scoped = behavior
        .scoped(to: stage, manager: manager)
      _ = try await scoped.result.get()
      XCTFail()
    } catch {
      didThrow = true
    }
    _ = await manager.behaviorResolutions
    XCTAssert(didThrow)
  }

  func test_get_eventual_throwingCancel() async throws {
    let never = Async.Value<Int>()
    let didRunTask = Async.Value<Bool>()
    var didThrow = false
    let behavior: Behaviors.AsyncSingle<Void, Int, Never> = Behaviors
      .make(.auto(), input: Void.self) { () async -> Int in
        await never.value
      }
    let scoped = behavior.scoped(to: stage, manager: manager)
    do {
      Task {
        await Flush.tasks()
        stage.dispose()
        await didRunTask.resolve(true)
      }
      _ = try await scoped.result.get()
      XCTFail()
    } catch {
      didThrow = true
    }
    XCTAssert(didThrow)
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
      .scoped(to: stage, manager: .init())
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

  func test_interception() async throws {
    let initial = 123_321
    let replacement = 100_000
    var received: Int?
    manager = .init(behaviorInterceptors: [
      BehaviorInterceptor(
        id: .id("test_interception"),
        type: Behaviors.AsyncSingle<Void, Int, Error>.self,
        subscriber: .init { _ in .throwing {
          replacement
        }}
      ),
    ])
    let behavior: Behaviors.AsyncSingle<Void, Int, Error> = Behaviors
      .make(.id("test_interception"), input: Void.self) { () async throws -> Int in
        initial
      }
    _ = behavior
      .scoped(to: stage, manager: manager)
      .onResult {
        switch $0 {
        case .success(let value):
          received = value
        case .failure:
          XCTFail()
        }
      }
    try await manager.awaitFinished()
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
